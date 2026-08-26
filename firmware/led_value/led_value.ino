// Flashed onto the Arduino UNO R4 WiFi by the ECW CI Job Smoke workflow.
//
// Change `val` below and open a PR to flip the onboard LED on/off and change
// what gets printed over serial. LED is on when val != 0, off when val == 0.
// The CI serial job captures the printed line; the CI camera job captures a
// photo of the board so you can see the LED state.
const int val = 1;

void setup() {
  Serial.begin(115200);
  pinMode(LED_BUILTIN, OUTPUT);
  digitalWrite(LED_BUILTIN, val != 0 ? HIGH : LOW);
}

void loop() {
  Serial.print("Your value is ");
  Serial.println(val);
  delay(1000);
}
