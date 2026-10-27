#ifndef HX_INCREMENTAL_IMPLEMENTATION_H
#define HX_INCREMENTAL_IMPLEMENTATION_H

// Included after MarkContext and allocation marking, with all mutators stopped
// whenever queues, ranges or cycle state are inspected.
namespace hx
{

std::atomic<bool> gIncrementalActive{false};
bool gIncrementalAllocationsWhite = false;
static thread_local double sIncrementalRequestMs = 0;

struct IncrementalRangeJob
{
   Object *owner;
   IncrementalRangeScan scan;
   size_t cursor = 0;
   size_t item = 0;
   bool queued = true;
   IncrementalRangeJob(Object *inOwner, IncrementalRangeScan inScan) : owner(inOwner), scan(inScan) {}
};

struct IncrementalState
{
   std::atomic<bool> failed{false};
   std::atomic<double> budgetMs{0.5};
   std::atomic<double> intervalMs{1.0};
   std::atomic<double> nextAutomatic{0};
   std::atomic<bool> automaticRunning{false};
   std::vector<IncrementalEntry> detached;
   size_t detachedRead = 0;
   bool logsPending = false;
   bool finishPending = false;
   std::vector<IncrementalRangeJob> ranges;
   std::unordered_map<Object *, size_t> rangeOwners;
   std::vector<size_t> rangeQueue;
   size_t rangeHead = 0;
   std::unordered_set<Object *> dirty;
   bool tracing = false;
   double deadline = 0;
   std::atomic<size_t> work{0};
   size_t slices = 0;
   std::mutex statsLock;
   uint64_t cycles = 0;
   uint64_t pauses = 0;
   uint64_t fallbacks = 0;
   uint64_t forcedFinishes = 0;
   uint64_t requestedSlices = 0;
   double maxSlicePauseMs = 0;
   double maxSynchronousPauseMs = 0;
   double totalPauseMs = 0;
   double maxPauseMs = 0;
   double lastPauseMs = 0;
   size_t lastSlices = 0;
   Object *watch = nullptr;
   Object *omit = nullptr;
   std::atomic<bool> watched{false};
   std::mutex rangeLock;
   size_t testWorkLimit = 0;

   void clearWork()
   {
      ranges.clear();
      rangeOwners.clear();
      rangeQueue.clear();
      rangeHead = 0;
      detached.clear();
      detachedRead = 0;
      logsPending = false;
      finishPending = false;
      dirty.clear();
      tracing = false;
      deadline = 0;
      work = 0;
   }

   void pause(double inStart, bool inBudgeted)
   {
      double elapsed = (IncrementalNow() - inStart) * 1000.0;
      std::lock_guard<std::mutex> lock(statsLock);
      pauses++;
      totalPauseMs += elapsed;
      lastPauseMs = elapsed;
      maxPauseMs = std::max(maxPauseMs, elapsed);
      if (inBudgeted)
      {
         requestedSlices++;
         maxSlicePauseMs = std::max(maxSlicePauseMs, elapsed);
      }
      else
         maxSynchronousPauseMs = std::max(maxSynchronousPauseMs, elapsed);
   }
};

static IncrementalState &IncrementalData()
{
   // Like the allocator, this survives static destruction and late threads.
   static IncrementalState *state = new IncrementalState();
   return *state;
}

static bool IncrementalExpired()
{
   IncrementalState &state = IncrementalData();
   if (!state.tracing || state.deadline <= 0)
      return false;
#ifdef HXCPP_GC_INCREMENTAL_TEST
   if (state.work > 0 && ((state.testWorkLimit && state.work >= state.testWorkLimit) || state.watched))
      return true;
#endif
   // Reading the clock for every pointer costs more than marking small
   // objects. Check in bounded batches without a shared counter cache line.
   static thread_local unsigned int checks = 0;
   return (++checks & 63) == 0 && IncrementalNow() >= state.deadline;
}

static void IncrementalScanned(Object *inObject)
{
#ifdef HXCPP_GC_INCREMENTAL_TEST
   IncrementalState &state = IncrementalData();
   if (!state.tracing)
      return;
   state.work++;
   if (inObject == state.watch)
      state.watched = true;
#endif
}

void IncrementalRemember(Object *inOwner, const void *inValue, StackContext *inCtx)
{
   if (!gIncrementalActive.load(std::memory_order_relaxed) || !inCtx)
      return;
   // A white holder will be scanned if it becomes reachable. Only a holder
   // already discovered by this cycle can hide an inserted edge from it.
   if (inOwner && reinterpret_cast<unsigned char *>(inOwner)[HX_ENDIAN_MARK_ID_BYTE] != gByteMarkID)
      return;
   if (inCtx->mIncrementalEntries.size() >= (1u << 20))
   {
      IncrementalData().failed.store(true, std::memory_order_relaxed);
      return;
   }
   try
   {
      inCtx->mIncrementalEntries.push_back({inOwner, inValue});
   }
   catch (const std::bad_alloc &)
   {
      IncrementalData().failed.store(true, std::memory_order_relaxed);
   }
}

void IncrementalAllocated(void *inValue, bool inObject, ImmixAllocator *inAlloc)
{
   if (!gIncrementalActive.load(std::memory_order_relaxed))
      return;
   if (IncrementalData().tracing)
   {
      // New objects are white too. A root or a store into a discovered
      // holder shades them, so transient objects do not flood the mark log.
      // Stores after a partially constructed object was discovered use the
      // same barrier as stores into any other discovered holder.
      static_cast<unsigned char *>(inValue)[HX_ENDIAN_MARK_ID_BYTE] = static_cast<unsigned char>(gPrevByteMarkID);
      return;
   }
   // Fresh headers already have the current epoch. Their rows must also be
   // live even if no subsequent pointer scan visits a primitive allocation.
   uintptr_t header = reinterpret_cast<uintptr_t>(inValue) - sizeof(unsigned int);
   unsigned int flags = *reinterpret_cast<unsigned int *>(header);
   unsigned int rows = flags & IMMIX_ALLOC_ROW_COUNT;
   unsigned char *row = reinterpret_cast<unsigned char *>(header & IMMIX_BLOCK_BASE_MASK) +
                        ((header & IMMIX_BLOCK_OFFSET_MASK) >> IMMIX_LINE_BITS);
   for (unsigned int i = 0; i < rows; i++)
      row[i] = 1;
}

void IncrementalMutationEnter(Object *inOwner, StackContext *inCtx)
{
   if (inCtx)
      inCtx->mIncrementalMutations++;
   IncrementalRemember(inOwner, nullptr, inCtx);
}

void IncrementalMutationLeave(Object *inOwner, StackContext *inCtx)
{
   IncrementalRemember(inOwner, nullptr, inCtx);
   if (inCtx)
      inCtx->mIncrementalMutations--;
}

static void IncrementalTransfer(StackContext *inCtx)
{
   IncrementalState &state = IncrementalData();
   try
   {
      state.detached.insert(state.detached.end(), inCtx->mIncrementalEntries.begin() + inCtx->mIncrementalRead, inCtx->mIncrementalEntries.end());
   }
   catch (const std::bad_alloc &)
   {
      state.failed.store(true, std::memory_order_relaxed);
   }
   inCtx->mIncrementalEntries.clear();
   inCtx->mIncrementalRead = 0;
}

bool IncrementalRange(Object *inOwner, IncrementalRangeScan inScan, MarkContext *inCtx)
{
   IncrementalState &state = IncrementalData();
   if (!state.tracing)
      return false;
   std::lock_guard<std::mutex> lock(state.rangeLock);
   if (state.failed.load(std::memory_order_relaxed))
      return true;
   try
   {
      if (state.ranges.size() >= (1u << 20))
      {
         state.failed.store(true, std::memory_order_relaxed);
         return true;
      }
      auto found = state.rangeOwners.find(inOwner);
      if (found == state.rangeOwners.end())
      {
         size_t index = state.ranges.size();
         state.ranges.emplace_back(inOwner, inScan);
         state.rangeOwners.emplace(inOwner, index);
         state.rangeQueue.push_back(index);
      }
      else
      {
         IncrementalRangeJob &job = state.ranges[found->second];
         if (!job.queued)
         {
            job.cursor = job.item = 0;
            job.queued = true;
            state.rangeQueue.push_back(found->second);
         }
      }
   }
   catch (const std::bad_alloc &)
   {
      // Keep the heap intact and restart synchronously at the next stop.
      // An exception must not escape a marker worker thread.
      state.failed.store(true, std::memory_order_relaxed);
   }
   return true;
}

static bool IncrementalEntries(std::vector<IncrementalEntry> &inEntries, size_t &ioRead, MarkContext *inCtx)
{
   IncrementalState &state = IncrementalData();
   while (ioRead < inEntries.size())
   {
      if (IncrementalExpired())
         return false;
      const IncrementalEntry &entry = inEntries[ioRead++];
      state.work++;
      if (entry.value)
      {
         unsigned int flags;
         memcpy(&flags, static_cast<const char *>(entry.value) - sizeof(flags), sizeof(flags));
         if (flags & IMMIX_ALLOC_IS_CONTAINER)
            MarkObjectAlloc(static_cast<Object *>(const_cast<void *>(entry.value)), inCtx);
         else
            MarkAlloc(const_cast<void *>(entry.value), inCtx);
         // Scalar insertion barriers shade the new target. They do not
         // invalidate an entire large container on every element write.
         continue;
      }
      if (!entry.owner)
         continue;
      try
      {
         if (!state.dirty.insert(entry.owner).second)
            continue;
      }
      catch (const std::bad_alloc &)
      {
         state.failed.store(true, std::memory_order_relaxed);
         return false;
      }
      MarkObjectAlloc(entry.owner, inCtx);
      // A black holder can acquire an edge after it was scanned. Revisit it
      // even if its ordinary header already belongs to this cycle.
      inCtx->pushObj(entry.owner);
      auto range = state.rangeOwners.find(entry.owner);
      if (range != state.rangeOwners.end())
      {
         IncrementalRangeJob &job = state.ranges[range->second];
         job.cursor = job.item = 0;
      }
   }
   inEntries.clear();
   ioRead = 0;
   return true;
}

static bool IncrementalDrain(MarkContext *inCtx, void (*inProcess)(MarkContext *, void *), void *inData)
{
   IncrementalState &state = IncrementalData();
   try
   {
      while (true)
      {
         if (state.failed.load(std::memory_order_relaxed))
            return false;
         inProcess(inCtx, inData);
         if (state.failed.load(std::memory_order_relaxed))
            return false;
         if (inCtx->hasWork())
            return false;
         if (state.rangeHead >= state.rangeQueue.size())
            return !state.logsPending;
         if (IncrementalExpired())
            return false;
         // Feed several ranges to one worker round. Waking the marker pool for
         // each 256-element chunk costs more than scanning those elements.
         for (int batch = 0; batch < 64 && state.rangeHead < state.rangeQueue.size(); batch++)
         {
            if (IncrementalExpired())
               break;
            size_t index = state.rangeQueue[state.rangeHead++];
            // Workers are stopped here. Scans enqueue objects; only their
            // later __Mark calls can append ranges and move this descriptor.
            IncrementalRangeJob &job = state.ranges[index];
            inCtx->init();
            bool complete = job.scan(job.owner, job.cursor, job.item, inCtx);
            state.work++;
            if (complete)
               job.queued = false;
            else
               state.rangeQueue.push_back(index);
         }
      }
   }
   catch (const std::bad_alloc &)
   {
      state.failed.store(true, std::memory_order_relaxed);
      return false;
   }
}

static void IncrementalDiscard(MarkContext *inCtx)
{
   inCtx->discardJobs();
   IncrementalData().clearWork();
   gIncrementalAllocationsWhite = false;
   gIncrementalActive.store(false, std::memory_order_relaxed);
}

} // namespace hx
#endif
