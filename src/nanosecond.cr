loop do 
 time = Time.local
  time_str = time.to_s("%d-%m-%Y %T.%3N")  # DD-MM-YYYY HH:MM:SS.mmm
  
  print "\r#{time_str}\e[K"
  STDOUT.flush
  sleep 1e9.nanoseconds / 144
end 
