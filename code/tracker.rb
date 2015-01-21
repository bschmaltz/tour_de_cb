#simplest ruby program to read from arduino serial,
#using the SerialPort gem
#(http://rubygems.org/gems/serialport)

require "serialport"
require 'httparty'

#@url = "http://10.10.32.236:3000/"
#@url = 'http://localhost:3000/distance'
@url = 'http://quiet-meadow-8187.herokuapp.com/distance'
#heroku jr@cb
#@secret_key = 'zBrkhwSaTsmccLvEZzBNQtkwkQnSsWyoAGwzKHmOtEBodaRtBw'

#@secret_key = "ymiECBAQpWjiKwhHGJAInZtBVkwkAihsnipCRGCpISnKGggmAJ"
#@secret_key = 'fHZdoebXSoNckbNVLxjXjupqGQavilvZRlqiEyNDqKHzbiisEc'
@secret_key

def post_rotations(rotations)

  @result = HTTParty.post(@url + "/#{rotations}",
                          :headers => { 'secret_key' => @secret_key,
                                        'Request-Type' => 'application/json',
                                        'Content-Type' => 'application/json'} )
end

CLOSED = 1
OPEN = 2

#params for serial port
port_str = "/dev/tty.usbmodem1411"  #may be different for you
baud_rate = 9600
data_bits = 8
stop_bits = 1
parity = SerialPort::NONE
speed = 3
time = 1

sp = SerialPort.new(port_str, baud_rate, data_bits, stop_bits, parity)
#binding.pry
#just read forever
rotations = 0
current_state = OPEN

current_time = Time.now

p "Exit with 'control + c'."

while true do
  while (i = sp.gets) do

    i = "0" if i.nil?
    if i.chomp == "1"
      rotations += speed
      p "New Rotation #{rotations}"
    end

    if (Time.now - current_time > time && rotations > 0)
      p rotations
      p post_rotations(rotations)
      rotations = 0
      current_time = Time.now
    end
    #puts i.class #String
  end
end

sp.close