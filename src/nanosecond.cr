GC.disable

loop do
  time = Time.local
  time_str = time.to_s("%d-%m-%Y %T.%3N")
  if ENV["ANDROID_ROOT"]?
    puts time_str
  else
    print "\r#{time_str}\e[K"
  end
  STDOUT.flush
  sleep 1e9.nanoseconds / 144
end
