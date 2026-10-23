#include <hxcpp.h>
#include "Cppia.h"
#include "CppiaStream.h"
#include <stdlib.h>
#include <atomic>
#include <mutex>
#include <new>


namespace hx
{


static int sScriptId = 0;
static std::atomic<int> sLiveModules(0);


const char **sgNativeNameSlots = 0;
int sgNativeNameSlotCount = 0;

// Every module not yet freed, loaded or released
static std::mutex sModuleLock;
static std::vector<CppiaModule *> &allModules()
{
   static std::vector<CppiaModule *> *modules = new std::vector<CppiaModule *>();
   return *modules;
}


// --- Module arena ----

static thread_local CppiaModule *sAllocModule = 0;

struct CppiaAllocScope
{
   CppiaModule *previous;
   CppiaAllocScope(CppiaModule *inModule) : previous(sAllocModule) { sAllocModule = inModule; }
   ~CppiaAllocScope() { sAllocModule = previous; }
};

struct CppiaBlock
{
   void (*destroy)(void *);
   // Zero for a block from malloc, made when no module was loading
   size_t size;
};
enum { CPPIA_BLOCK_HEADER = 16, CPPIA_ARENA_CHUNK = 64*1024 };

void *cppiaAlloc(size_t inSize, void (*inDestroy)(void *))
{
   size_t total = (CPPIA_BLOCK_HEADER + inSize + 15) & ~(size_t)15;
   CppiaBlock *block;
   if (sAllocModule)
   {
      block = (CppiaBlock *)sAllocModule->arenaAlloc(total);
      block->size = total;
   }
   else
   {
      block = (CppiaBlock *)malloc(total);
      if (!block)
         throw std::bad_alloc();
      block->size = 0;
   }
   block->destroy = inDestroy;
   return (char *)block + CPPIA_BLOCK_HEADER;
}

void cppiaFree(void *inPtr)
{
   if (!inPtr)
      return;
   CppiaBlock *block = (CppiaBlock *)((char *)inPtr - CPPIA_BLOCK_HEADER);
   if (block->size)
      block->destroy = 0;
   else
      free(block);
}

void *CppiaModule::arenaAlloc(size_t inSize)
{
   ArenaChunk chunk;
   if (inSize > CPPIA_ARENA_CHUNK/4)
   {
      // A chunk of its own, before the one still filling
      chunk.base = (char *)malloc(inSize);
      if (!chunk.base)
         throw std::bad_alloc();
      chunk.size = chunk.used = inSize;
      arena.insert(arena.empty() ? arena.end() : arena.end()-1, chunk);
      return chunk.base;
   }
   if (arena.empty() || arena.back().used + inSize > arena.back().size)
   {
      chunk.base = (char *)malloc(CPPIA_ARENA_CHUNK);
      if (!chunk.base)
         throw std::bad_alloc();
      chunk.size = CPPIA_ARENA_CHUNK;
      chunk.used = 0;
      arena.push_back(chunk);
   }
   ArenaChunk &last = arena.back();
   void *result = last.base + last.used;
   last.used += inSize;
   return result;
}

bool CppiaModule::ownsMemory(const void *inPtr) const
{
   const char *ptr = (const char *)inPtr;
   for(size_t i=0;i<arena.size();i++)
      if (ptr>=arena[i].base && ptr<arena[i].base + arena[i].used)
         return true;
   return false;
}



// --- CppiaModule ----

CppiaModule::CppiaModule()
{
   main = 0;
   layout = 0;
   creatingClass = 0;
   creatingFunction = 0;
   owner = 0;
   released = false;
   scriptId = ++sScriptId;
   sLiveModules++;
   strings = Array_obj<String>::__new(0,0);
   if (sgNativeNameSlotCount>0)
      for(int i=2;i<sgNativeNameSlotCount;i++)
         interfaceSlots[sgNativeNameSlots[i]] = i;

   std::lock_guard<std::mutex> lock(sModuleLock);
   allModules().push_back(this);
}

void CppiaModule::setDebug(CppiaExpr *outExpr, int inFileId, int inLine)
{
   #ifdef HXCPP_DEBUGGER
   if (inFileId)
      allFileIds.insert(inFileId);
   #endif
   outExpr->className = creatingClass;
   outExpr->functionName = creatingFunction;
   //outExpr->filename = cStrings[inFileId].c_str();
   outExpr->filename = strings[inFileId].utf8_str();
   outExpr->line = inLine;
}


// --- CppiaModule -------------------------

// Runs in a collection, so it must not allocate from the collector
CppiaModule::~CppiaModule()
{
   sLiveModules--;
   for(size_t c=0;c<arena.size();c++)
   {
      char *ptr = arena[c].base;
      char *end = ptr + arena[c].used;
      while(ptr<end)
      {
         CppiaBlock *block = (CppiaBlock *)ptr;
         if (block->destroy)
         {
            void (*destroy)(void *) = block->destroy;
            block->destroy = 0;
            destroy(ptr + CPPIA_BLOCK_HEADER);
         }
         ptr += block->size;
      }
   }
   for(size_t c=0;c<arena.size();c++)
      free(arena[c].base);
   for(size_t r=0;r<resources.size();r++)
      if (resources[r].mData)
         free((unsigned char *)resources[r].mData - 4);
}

void CppiaModule::link()
{
   DBGLOG("Resolve registered - super\n");
   HaxeNativeClass::link();
   
   DBGLOG("Resolve typeIds\n");
   for(int t=0;t<types.size();t++)
      types[t]->link(*this);

   DBGLOG("Resolve inherited atributes\n");
   for(int i=0;i<classes.size();i++)
   {
      classes[i]->linkTypes();
   }

   for(int i=0;i<classes.size();i++)
   {
      linkingClass = classes[i];
      classes[i]->link();
   }
   linkingClass = 0;

   if (main)
      main = (ScriptCallable *)main->link(*this);

   if (!linkMisses.empty())
   {
      std::string message = "Could not link ";
      for(size_t i=0;i<linkMisses.size();i++)
      {
         if (i)
            message += ", ";
         message += linkMisses[i];
      }
      hx::Throw( String::create(message.c_str(), (int)message.size()) );
   }
}

#ifdef CPPIA_JIT
void CppiaModule::compile()
{
   for(int i=0;i<classes.size();i++)
      classes[i]->compile();

   if (main)
      main->compile();
}
#endif

void addScriptableClass(String inName);
void addScriptableFile(String inName);

void CppiaModule::registerDebugger()
{
   #ifdef HXCPP_DEBUGGER
   for(int i=0;i<classes.size();i++)
   {
      String scriptable(classes[i]->name.c_str());
      addScriptableClass( scriptable.makePermanent().utf8_str() );
   }

   for(std::unordered_set<int>::const_iterator i = allFileIds.begin(); i!=allFileIds.end(); ++i)
      addScriptableFile(strings[*i]);

   // Lets a debugger set breakpoints in the files this script brought
   if (hx::g_onScriptLoadedFunction.mPtr)
      hx::g_onScriptLoadedFunction();

   #endif
}

CppiaClassInfo *CppiaModule::findClass( ::String inName)
{

   std::string stdName(inName.utf8_str());
   for(int i=0;i<classes.size();i++)
      if (classes[i]->name == stdName)
         return classes[i];
   return 0;
}


// The data the module holds goes now; its code goes once nothing reaches the module
void CppiaModule::release()
{
   for(int i=0;i<classes.size();i++)
      classes[i]->release();
   if (resources.size())
      UnregisterResources(&resources[0]);
}

void CppiaModule::mark(hx::MarkContext *__inCtx)
{
   DBGLOG(" --- MARK --- \n");
   HX_MARK_MEMBER(strings);
   for(int i=0;i<types.size();i++)
   {
      if (types[i]) /* May be partially constructed */
         types[i]->mark(__inCtx);
   }
   for(int i=0;i<markable.size();i++)
   {
      markable[i]->mark(__inCtx);
   }
   for(int i=0;i<classes.size();i++)
      if (classes[i])
      {
         classes[i]->mark(__inCtx);
      }
}

#ifdef HXCPP_VISIT_ALLOCS
void CppiaModule::visit(hx::VisitContext *__inCtx)
{
   HX_VISIT_MEMBER(strings);
   for(int i=0;i<types.size();i++)
      types[i]->visit(__inCtx);
   for(int i=0;i<markable.size();i++)
      markable[i]->visit(__inCtx);
   for(int i=0;i<classes.size();i++)
      if (classes[i])
         classes[i]->visit(__inCtx);
}
#endif


void cppiaClassInit(CppiaClassInfo *inClass, CppiaCtx *ctx, int inPhase);



void CppiaModule::boot(CppiaCtx *ctx)
{
   // boot (statics)
   for(int i=0;i<classes.size();i++)
      cppiaClassInit(classes[i],ctx,0);
   // run __init__
   for(int i=0;i<classes.size();i++)
      cppiaClassInit(classes[i],ctx,1);
}

int CppiaModule::getInterfaceSlot(const std::string &inName)
{
   InterfaceSlots::iterator it = interfaceSlots.find(inName);
   if (it==interfaceSlots.end())
   {
      int result = interfaceSlots.size()+1;
      interfaceSlots[inName] = result;
      return result;
   }
   return it->second;
}


int CppiaModule::findInterfaceSlot(const std::string &inName)
{
   InterfaceSlots::iterator it = interfaceSlots.find(inName);
   if (it==interfaceSlots.end())
      return -1;
   return it->second;
}




// Each thing is named once, at the first place the script uses it
void CppiaModule::linkMiss(CppiaExpr *inWhere, const std::string &inWhat)
{
   for(size_t i=0;i<linkMisses.size();i++)
      if (linkMisses[i].compare(0, inWhat.size(), inWhat)==0 &&
          (linkMisses[i].size()==inWhat.size() || linkMisses[i][inWhat.size()]==' '))
         return;

   std::string miss = inWhat;
   if (inWhere && inWhere->filename && inWhere->line>0 && strcmp(inWhere->filename,"?"))
      miss += " (" + std::string(inWhere->filename) + ":" + std::to_string(inWhere->line) + ")";
   linkMisses.push_back(miss);
}

void CppiaModule::where(CppiaExpr *e)
{
   if (linkingClass && layout)
      CPPIALOG(" in %s::%p\n", linkingClass->name.c_str(), layout);
   CPPIALOG("   %s at %s:%d %s\n", e->getName(), e->filename, e->line, e->functionName);
}



void ScriptableRegisterNameSlots(const char *inNames[], int inLength)
{
   sgNativeNameSlots = inNames;
   sgNativeNameSlotCount = inLength;
}


// --- CppiaConst -------------------------------------------

CppiaConst::CppiaConst() : type(cNull), ival(0), dval(0) { }

void CppiaConst::fromStream(CppiaStream &stream)
{
   std::string tok = stream.getToken();
   if (tok[0]=='i')
   {
      type = cInt;

      dval = ival = stream.getInt();
   }
   else if (tok=="true")
   {
      type = cInt;
      dval = ival = 1;
   }
   else if (tok=="false")
   {
      type = cInt;
      dval = ival = 0;
   }
   else if (tok[0]=='f')
   {
      type = cFloat;
      int strIndex = stream.getStringId();
      String val = stream.module->strings[strIndex];
      dval = atof(val.out_str());
      ival = dval;
   }
   else if (tok[0]=='s')
   {
      type = cString;
      ival = stream.getInt();
   }
   else if (tok=="NULL")
      type = cNull;
   else if (tok=="THIS")
      type = cThis;
   else if (tok=="SUPER")
      type = cSuper;
   else
      throw "unknown const value";
}




// --- CppiaLoadedModule -------------------------------------------





// Cppia Object - manage
class CppiaObject : public hx::CppiaLoadedModule_obj
{
public:
   CppiaModule *cppia;
   bool        booted;

   // A loaded module is a root until it is released
   CppiaObject(CppiaModule *inModule)
   {
      cppia = inModule;
      booted = false;
      cppia->owner = this;
      GCAddRoot(&cppia->owner);
   }
   void __Mark(hx::MarkContext *ctx) HXCPP_OVERRIDE { cppia->mark(ctx); }
#ifdef HXCPP_VISIT_ALLOCS
   void __Visit(hx::VisitContext *__inCtx) HXCPP_OVERRIDE
   {
      cppia->visit(__inCtx);
      HX_VISIT_OBJECT(cppia->owner);
   }
#endif


   void boot() HXCPP_OVERRIDE
   {
      if (booted)
         return;

      booted = true;
      try
      {
         DBGLOG("--- Boot --------------------------------------------\n");
         CppiaCtx *ctx = CppiaCtx::getCurrent();
         cppia->boot(ctx);
      }
      catch(const char *errorString)
      {
         String error(errorString);
         hx::Throw(error);
      }
   }


   void run() HXCPP_OVERRIDE
   {
      if (!booted)
         boot();
      if (cppia->main)
      {
         try
         {
            //__hxcpp_enable(false);
            DBGLOG("--- Run --------------------------------------------\n");
            CppiaCtx *ctx = CppiaCtx::getCurrent();
            {
               // Main gets a frame of its own, which is given back when it returns
               unsigned char *pointer = ctx->pointer;
               ctx->push( (hx::Object *) 0 );
               AutoStack save(ctx,pointer);
               ctx->runVoid(cppia->main);
            }
            if (ctx->exception)
            {
               hx::Object *e = ctx->exception;
               ctx->exception = 0;
               hx::Throw( Dynamic(e) );
            }
         }
         catch(const char *errorString)
         {
            String error(errorString);
            hx::Throw(error);
         }
      }
   }

   ::hx::Class resolveClass( ::String inName) HXCPP_OVERRIDE
   {
      CppiaClassInfo *info = cppia->findClass(inName);
      if (info)
         return info->getClass();
      return null();
   }

   // The module stops being a root; it is freed by the first collection that finds nothing
   // reaching this object
   void release() HXCPP_OVERRIDE
   {
      {
         std::lock_guard<std::mutex> lock(sModuleLock);
         if (cppia->released)
            return;
         cppia->released = true;
      }
      cppia->release();
      GCRemoveRoot(&cppia->owner);
   }

   // The std's Module extern does not declare release, so untyped calls
   // reach it as a field
   struct ReleaseFunc : public hx::LocalFunc
   {
      hx::Object *module;
      ReleaseFunc(hx::Object *inModule) : module(inModule) { }
      Dynamic __run() HXCPP_OVERRIDE
      {
         static_cast<CppiaObject *>(module)->release();
         return null();
      }
      int __ArgCount() const HXCPP_OVERRIDE { return 0; }
      void __Mark(hx::MarkContext *__inCtx) HXCPP_OVERRIDE { HX_MARK_MEMBER(module); }
      #ifdef HXCPP_VISIT_ALLOCS
      void __Visit(hx::VisitContext *__inCtx) HXCPP_OVERRIDE { HX_VISIT_OBJECT(module); }
      #endif
   };

   hx::Val __Field(const String &inName, hx::PropertyAccess inCallProp) HXCPP_OVERRIDE
   {
      if (inName==HX_CSTRING("release"))
         return Dynamic(new ReleaseFunc(this));
      return hx::CppiaLoadedModule_obj::__Field(inName, inCallProp);
   }

};


/*
 A loaded module is an ordinary GC object, so a generational collection stops traversing it once it
 is old. What it holds can still change after that: a literal boxes itself on first use, the JIT
 embeds that box in its code, a script static is assigned. None of those writes has a barrier, so a
 minor collection freed the young object while the old module still pointed at it.

 So every loaded module is marked on every collection, the way class statics are. A released module
 is too in a minor collection; a full one reaches it only through its CppiaObject, so it can be freed.
*/
void scriptMarkModules(hx::MarkContext *__inCtx, bool inGenerational)
{
   std::lock_guard<std::mutex> lock(sModuleLock);
   std::vector<CppiaModule *> &modules = allModules();
   for(size_t i=0;i<modules.size();i++)
      if (!modules[i]->released || inGenerational)
         modules[i]->mark(__inCtx);
}

#ifdef HXCPP_VISIT_ALLOCS
void scriptVisitModules(hx::VisitContext *__inCtx)
{
   std::lock_guard<std::mutex> lock(sModuleLock);
   std::vector<CppiaModule *> &modules = allModules();
   for(size_t i=0;i<modules.size();i++)
   {
      modules[i]->visit(__inCtx);
      HX_VISIT_OBJECT(modules[i]->owner);
   }
}
#endif


#ifdef HXCPP_STACK_TRACE
void GCForEachStackContext(void (*inFunc)(StackContext *, void *), void *inData);

static const char *copyPositionString(const char *inString)
{
   if (!inString)
      return 0;
   size_t len = strlen(inString) + 1;
   char *result = (char *)malloc(len);
   memcpy(result, inString, len);
   return result;
}

static std::string positionKey(const char *inString)
{
   return inString ? std::string(inString) : std::string();
}

// An exception stack can still show functions of a freed module; they get copies kept by content,
// so reloading the same code adds none
static const StackPosition *keepPosition(const StackPosition *inPosition)
{
   static std::map<std::string, StackPosition *> *kept = new std::map<std::string, StackPosition *>();
   std::string key = positionKey(inPosition->className) + '\n' + positionKey(inPosition->functionName) + '\n' +
                     positionKey(inPosition->fullName) + '\n' + positionKey(inPosition->fileName);
   StackPosition *&copy = (*kept)[key];
   if (!copy)
   {
      copy = new StackPosition(*inPosition);
      copy->className = copyPositionString(inPosition->className);
      copy->functionName = copyPositionString(inPosition->functionName);
      copy->fullName = copyPositionString(inPosition->fullName);
      copy->fileName = copyPositionString(inPosition->fileName);
      #ifdef HXCPP_STACK_SCRIPTABLE
      copy->scriptCallable = 0;
      #endif
   }
   return copy;
}

static void keepPositions(QuickVec<ExceptionStackFrame> &ioStack, std::vector<CppiaModule *> &inFreed)
{
   for(int i=0;i<ioStack.size();i++)
      for(size_t m=0;m<inFreed.size();m++)
         if (inFreed[m]->ownsMemory(ioStack[i].position))
         {
            ioStack[i].position = keepPosition(ioStack[i].position);
            break;
         }
}

static void keepContextPositions(StackContext *inCtx, void *inFreed)
{
   std::vector<CppiaModule *> &freed = *(std::vector<CppiaModule *> *)inFreed;
   keepPositions(inCtx->mExceptionStack, freed);
   keepPositions(inCtx->mOuterExceptionStack, freed);
}
#endif

// Called by each collection once marking and finalizers are done, with every thread stopped
void scriptFreeModules()
{
   // They remember function names by address
   #if !defined(HXCPP_PROFILER) && !defined(HXCPP_TELEMETRY)
   std::vector<CppiaModule *> freed;
   {
      std::lock_guard<std::mutex> lock(sModuleLock);
      std::vector<CppiaModule *> &modules = allModules();
      for(size_t i=0;i<modules.size(); )
      {
         if (modules[i]->released && !IsWeakRefValid(modules[i]->owner))
         {
            freed.push_back(modules[i]);
            modules.erase(modules.begin()+i);
         }
         else
            i++;
      }
   }
   if (freed.empty())
      return;

   #ifdef HXCPP_STACK_TRACE
   GCForEachStackContext(keepContextPositions, &freed);
   #endif

   for(size_t i=0;i<freed.size();i++)
      delete freed[i];
   #endif
}


int CppiaStream::getTypeId()
{
   int id = getInt();
   if (id<0 || id>=(int)module->types.size())
      throw "Bad type id";
   return id;
}

int CppiaStream::getStringId()
{
   int id = getInt();
   if (id<0 || id>=module->strings->length)
      throw "Bad string id";
   return id;
}

CppiaLoadedModule LoadCppia(const unsigned char *inData, int inDataLength)
{
   CppiaModule   *cppiaPtr = new CppiaModule();
   CppiaLoadedModule loadedModule = new CppiaObject(cppiaPtr);

   String error;
   {
   CppiaAllocScope allocScope(cppiaPtr);

   CppiaModule   &cppia = *cppiaPtr;
   CppiaStream stream(cppiaPtr,inData, inDataLength);

   try
   {
      std::string tok = stream.getAsciiToken();
      if (tok!="CPPIA" && tok!="CPPIB")
         throw "Bad magic";

      stream.setBinary(tok=="CPPIB");

      int stringCount = stream.checkCount(stream.getAsciiInt());
      for(int s=0;s<stringCount;s++)
         cppia.strings[s] = stream.readString();

      int typeCount = stream.checkCount(stream.getAsciiInt());
      cppia.types.resize(typeCount);
      DBGLOG("Type count : %d\n", typeCount);
      for(int t=0;t<typeCount;t++)
         cppia.types[t] = new TypeData(stream.readString());

      int classCount = stream.checkCount(stream.getAsciiInt());
      DBGLOG("Class count : %d\n", classCount);

      if (stream.binary)
      {
         int newLine = stream.getByte();
         if (newLine!='\n')
            throw "Missing new-line after class count";
      }

      cppia.classes.reserve(classCount);
      for(int c=0;c<classCount;c++)
      {
         // Listed while it loads, so the module marks its class object
         CppiaClassInfo *info = new CppiaClassInfo(cppia);
         cppia.classes.push_back(info);
         if (!info->load(stream))
            cppia.classes.pop_back();
      }

      tok = stream.getToken();
      if (tok=="MAIN")
      {
         DBGLOG("Main...\n");
         cppia.main = new ScriptCallable(createCppiaExpr(stream));
         cppia.main->className = "cppia";
         cppia.main->functionName = "__cppia_main";
         cppia.main->staticEntry = true;
      }
      else if (tok!="NOMAIN")
         throw "no main specified";

      tok = stream.getToken();
      if (tok=="RESOURCES")
      {
         int count = stream.checkCount(stream.getInt());
         std::vector<hx::Resource> &scriptResources = cppia.resources;
         scriptResources.resize(count+1);
         for(int r=0;r<count;r++)
         {
            tok = stream.getToken();
            if (tok!="RESO")
               throw "no reso tag";

            scriptResources[r].mName = cppia.strings[stream.getStringId()];
            scriptResources[r].mDataLength = stream.checkCount(stream.getInt());
         }
         if (!stream.binary)
            stream.skipChar();

         for(int r=0;r<count;r++)
         {
            int len = scriptResources[r].mDataLength;
            unsigned char *buffer = (unsigned char *)malloc(len+5);
            if (!buffer)
               throw "Out of memory";
            scriptResources[r].mData = buffer + 4;
            *(unsigned int *)buffer = HX_GC_CONST_ALLOC_BIT;
            buffer[len+5-1] = '\0';
            stream.readBytes(buffer+4, len);
            #ifdef HX_SMART_STRINGS_1
            unsigned char *p = (unsigned char *)buffer+4;
            unsigned char *end = p + len;
            while(!hasBig && p<end)
               if (*p++>127)
               {
                  *(unsigned int *)buffer |= HX_GC_STRING_CHAR16_T;
                  break;
               }
            #endif
         }
         scriptResources[count].mDataLength = 0;
         scriptResources[count].mData = 0;
         scriptResources[count].mName = String();
         
         RegisterResources(&scriptResources[0]);
      }
      else
         throw "no resources tag";


   }
   catch(const char *errorString)
   {
      error = HX_CSTRING("Error reading file ") + String(errorString) + 
                HX_CSTRING(", line ") + String(stream.line) + HX_CSTRING(", char ") + 
                   String(stream.pos);
   }
   catch(const std::exception &e)
   {
      error = HX_CSTRING("Error reading file ") + String(e.what());
   }
   catch(Dynamic e)
   {
      loadedModule->release();
      throw;
   }

   if (!error.raw_ptr())
      try
      {
         DBGLOG("Link...\n");
         cppia.link();
      }
      catch(const char *errorString)
      {
         error = String(errorString);
      }
      catch(Dynamic e)
      {
         loadedModule->release();
         throw;
      }

   #ifdef CPPIA_JIT
   bool jit = gEnableJit && CppiaCompiler::canRun();
   if (gEnableJit && !jit)
      CppiaCompiler::reportCannotRun();
   #else
   bool jit = false;
   #endif

   if (jit)
   {
      #ifdef CPPIA_JIT
      if (!error.raw_ptr())
         try
         {
            DBGLOG("Compile...\n");
            cppia.compile();
         }
         catch(const char *errorString)
         {
            error = String(errorString);
         }
         catch(Dynamic e)
         {
            loadedModule->release();
            throw;
         }
      #endif
   }
   }

   // The host never sees a module that failed to load, so it cannot release it
   if (error.raw_ptr())
   {
      loadedModule->release();
      hx::Throw(error);
   }

   cppiaPtr->registerDebugger();

   return loadedModule;
}





Array<String > gAllClasses;
Array<String > gAllFiles;

void addScriptableClass(String inName)
{
   #ifdef HXCPP_DEBUGGER
   if (!gAllClasses.mPtr)
   {
      gAllClasses = Array_obj<Dynamic>::__new();
      GCAddRoot( (hx::Object **)&gAllClasses.mPtr );
   }
   if (gAllClasses->indexOf(inName)<0)
      gAllClasses->push(inName);
   #endif
}


void addScriptableFile(String inName)
{
   #ifdef HXCPP_DEBUGGER
   if (!gAllFiles.mPtr)
   {
      gAllFiles = Array_obj<Dynamic>::__new();
      GCAddRoot( (hx::Object **)&gAllFiles.mPtr );
   }
   if (gAllFiles->indexOf(inName)<0)
      gAllFiles->push(inName);
   #endif
}








} // end namespace hx




#ifdef HXCPP_STACK_SCRIPTABLE

void __hxcpp_dbg_getScriptableVariables(hx::StackFrame *inFrame, ::Array<Dynamic> outNames)
{
   hx::ScriptCallable *callable = inFrame->position->scriptCallable;
   if (callable)
      callable->getScriptableVariables(inFrame->scriptStack, outNames);
}

bool __hxcpp_dbg_getScriptableValue(hx::StackFrame *inFrame, String inName, ::Dynamic &outValue)
{
   hx::ScriptCallable *callable = inFrame->position->scriptCallable;
   if (callable)
      return callable->getScriptableValue(inFrame->scriptStack, inName, outValue);
   return false;
}


bool __hxcpp_dbg_setScriptableValue(hx::StackFrame *inFrame, String inName, ::Dynamic inValue)
{
   hx::ScriptCallable *callable = inFrame->position->scriptCallable;
   if (callable)
      return callable->setScriptableValue(inFrame->scriptStack, inName, inValue);
   return false;
}

#endif





#ifdef HXCPP_DEBUGGER
void __hxcpp_dbg_getScriptableFiles( Array< ::String> ioPaths )
{
   Array<String> merge = hx::gAllFiles;
   if (merge.mPtr)
      for(int i=0;i< merge->length; i++)
      {
         if (ioPaths->indexOf( merge[i] ) < 0)
            ioPaths->push( merge[i] );
      }
}

void __hxcpp_dbg_getScriptableFilesFullPath( Array< ::String> ioPaths )
{
   __hxcpp_dbg_getScriptableFiles( ioPaths );
}

void __hxcpp_dbg_getScriptableClasses( Array< ::String> ioClasses )
{
   Array<String> merge = hx::gAllClasses;
   if (merge.mPtr)
      for(int i=0;i< merge->length; i++)
      {
         if (ioClasses->indexOf( merge[i] ) < 0)
            ioClasses->push( merge[i] );
      }
}

#endif



int __scriptable_cppia_live_modules()
{
   return hx::sLiveModules;
}

bool __scriptable_cppia_jit_active()
{
   #ifdef CPPIA_JIT
   return hx::gEnableJit && hx::CppiaCompiler::canRun();
   #else
   return false;
   #endif
}

::hx::CppiaLoadedModule __scriptable_cppia_from_string(String inCode)
{
   const unsigned char *code = (const unsigned char *)inCode.raw_ptr();
   int length = inCode.length;
   #ifdef HX_SMART_STRINGS
   if (inCode.isUTF16Encoded())
   {
      code = (const unsigned char *)inCode.utf8_str();
      length = strlen( (const char *)code );
   }
   #endif

   return hx::LoadCppia(code,length);
}


::hx::CppiaLoadedModule __scriptable_cppia_from_data(Array<unsigned char> inCode)
{
   return hx::LoadCppia( (unsigned char *)inCode->GetBase() ,inCode->length);
}


void __scriptable_load_cppia(String inCode)
{
   const unsigned char *code = (const unsigned char *)inCode.raw_ptr();
   int length = inCode.length;
   #ifdef HX_SMART_STRINGS
   if (inCode.isUTF16Encoded())
   {
      code = (const unsigned char *)inCode.utf8_str();
      length = strlen( (const char *)code );
   }
   #endif

   ::hx::CppiaLoadedModule module = hx::LoadCppia(code,length);

   module->boot();
   module->run();
}

