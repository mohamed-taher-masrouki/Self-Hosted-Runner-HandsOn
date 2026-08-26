// Flashed onto the Arduino UNO R4 WiFi by the ECW CI Job Smoke workflow.
//
// Change `val` below and open a PR to change what gets printed over serial.
// The CI serial job captures the printed line; the CI camera job captures a
// photo of the board so you can see the LED lit.
const int val = 1;

void setup() {
  Serial.begin(115200);
  pinMode(LED_BUILTIN, OUTPUT);
  digitalWrite(LED_BUILTIN, HIGH);
}

void loop() {
  Serial.print("Your value is ");
  Serial.println(val);
  delay(1000);
}
