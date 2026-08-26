// Flashed onto the Arduino UNO R4 WiFi by the ECW CI Job Smoke workflow.
//
// Change `val` below and open a PR to flip the onboard LED on/off and change
// what gets printed over serial. The CI serial job captures the printed
// line; the CI camera job captures a photo of the board so you can see the
// LED state.
const bool val = true;

void setup() {
  Serial.begin(9600);
  pinMode(LED_BUILTIN, OUTPUT);
}

void loop() {
  digitalWrite(LED_BUILTIN, val ? HIGH : LOW);
  Serial.print("Your value is ");
  Serial.println(val ? "on" : "off");
  delay(1000);
}
