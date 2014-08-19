function CallbackBarrier() {
  this.callbackHandle = null;
  this.asyncCount = 0;
  this.finalized = false;
}

CallbackBarrier.prototype.setBarrier = function() {
  if (this.finalized) {
    throw "You can't add a callback after finalizing";
  }
  this.asyncCount++;
}

CallbackBarrier.prototype.tryCallback = function() {  
  this.asyncCount--;
  if (this.asyncCount === 0 && this.finalized) {
    this.callbackHandle();
  }
}

CallbackBarrier.prototype.finalize = function(callback) {
  this.callbackHandle = callback;
  this.finalized = true;
  if (this.asyncCount === 0) {
    this.callbackHandle();
  }
}

// The console.log will now happen after the window is loaded and has been clicked and resized.
// This does make the assumption that getCallback() is called before finalize(), i.e. is not itself executed in a callback.
// This is intended to avoid having to manually count your callbacks. Meh. Tradeoffs.