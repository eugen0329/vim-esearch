fu! esearch#middleware#prewarm#apply(esearch) abort
  " All the prewarmers should be called before the commandline start to do
  " prewarming while user inputting the string
  call esearch#ftdetect#async_prewarm_cache()

  return a:esearch
endfu
