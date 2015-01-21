int analogPin = 0;     // potentiometer wiper (middle terminal) connected to analog pin 3
                       // outside leads to ground and +5V
int raw = 0;           // variable to store the raw input value
int out = 0;

void setup()
{
  Serial.begin(9600);             // Setup serial
  digitalWrite(13, HIGH);         // Indicates that the program has intialized
}

void loop()
{
  raw = analogRead(analogPin);    // Reads the Input PIN
  if (raw == 0) {
    out = 1;
  }
  else {
    out = 2;
  }
  
  Serial.print(out);
  delay(10);
}
