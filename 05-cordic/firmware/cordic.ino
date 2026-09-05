#include <SPI.h>
#include <math.h>

#define MISO_PIN  16 
#define CS_PIN    17 
#define SCK_PIN   18 
#define MOSI_PIN  19 

SPISettings spiSettings(1000000, MSBFIRST, SPI_MODE0);

void setup() {
  Serial.begin(115200);
  
  pinMode(CS_PIN, OUTPUT);
  digitalWrite(CS_PIN, HIGH); 

  SPI.setRX(MISO_PIN);
  SPI.setTX(MOSI_PIN);
  SPI.setSCK(SCK_PIN);
  SPI.begin();
  
  while (!Serial && millis() < 3000);
  
  Serial.println("CORDIC");
  Serial.println("Enter angle in degrees:");
  printTable();
}

void loop() {
  if (Serial.available() > 0) {
    String input = Serial.readStringUntil('\n');
    input.trim();

    if (input.length() > 0) {
      float angle = input.toFloat();
      float c_cos, c_sin;
      
      // Read CORDIC twice to update pipeline
      queryCordic(angle, c_cos, c_sin);
      queryCordic(angle, c_cos, c_sin);

      float rad = angle * (M_PI / 180.0f);
      float ref_cos = cosf(rad);
      float ref_sin = sinf(rad);
      
      float err_cos = fabsf(ref_cos - c_cos);
      float err_sin = fabsf(ref_sin - c_sin);

      printRow(angle, c_cos, ref_cos, err_cos, c_sin, ref_sin, err_sin);
    }
  }
}

void queryCordic(float angle, float &cos_out, float &sin_out) {
  while (angle >= 180.0f) angle -= 360.0f;
  while (angle < -180.0f) angle += 360.0f;

  int16_t angle_raw = (int16_t)(angle * (32767.0f / 180.0f));

  SPI.beginTransaction(spiSettings);
  digitalWrite(CS_PIN, LOW);
  
  uint16_t cos_raw = SPI.transfer16(angle_raw); 
  uint16_t sin_raw = SPI.transfer16(0x0000);    
  
  digitalWrite(CS_PIN, HIGH);
  SPI.endTransaction();

  cos_out = (float)((int16_t)cos_raw) / 32767.0f;
  sin_out = (float)((int16_t)sin_raw) / 32767.0f;
}

void printTable() {
  Serial.println("Angle | CORDIC Cos | Actual Cos | Cos Error | CORDIC Sin | Actual Sin | Sin Error");
}

void printRow(float angle, float c_cos, float ref_cos, float err_cos, float c_sin, float ref_sin, float err_sin) {
  char buf[120];
  snprintf(buf, sizeof(buf), "%.1f | %.4f | %.4f | %.5f | %.4f | %.4f | %.5f",
           angle, c_cos, ref_cos, err_cos, c_sin, ref_sin, err_sin);
  Serial.println(buf);
}
