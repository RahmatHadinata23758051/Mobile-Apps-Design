#include <Arduino.h>
#include <SPI.h>                // Library untuk komunikasi SPI
#include <Wire.h>               // Library untuk komunikasi I2C
#include <Adafruit_ADS1X15.h>   // Library untuk ADS1115
#include <RTClib.h>             // Library untuk RTC DS3231
#include <OneWire.h>            // Library untuk DS18B20
#include <DallasTemperature.h>  // Library untuk DS18B20
#include <DHT.h>                // Library untuk DHT22
#include <WiFi.h>               // Library untuk Wifi
#include <PubSubClient.h>       // Library untuk MQTT
#include <ArduinoJson.h>        // Library untuk tipe data Json
#include <BluetoothSerial.h>    // Library untuk Bluetooth Serial

// Deklarasi Konstanta
#define DHT_PIN 5               // Pin data DHT22
#define DHT_TYPE DHT22          // Tipe sensor DHT
#define ONE_WIRE_BUS 4          // Pin data DS18B20
#define TDS_SENSOR_CHANNEL 0    // ADS1115 Channel A0
#define DEFAULT_WATER_TEMP 25.0 // Default Suhu Air
#define ADC_MAX 32767.0         // Nilai ADC
#define ADC_REF_VOLTAGE 3.3     // Voltase pin ADC
#define MAX_RETRY 5             // Banyak inisialisasi ulang
#define RETRY_DELAY 1000        // Delay inisialisasi ulang selama 1 detik

//Deklarasi Wifi
const char *ssid = "MAKER 2024";
const char *password = "Makerdotindo24";

//Deklarasi MQTT
const char *mqtt_broker = "broker.emqx.io";
const char *topic = "emqx/esp32";
const char *mqtt_username = "emqx";
const char *mqtt_password = "public";
const int mqtt_port = 1883;

// Deklarasi Variabel
DHT dht(DHT_PIN, DHT_TYPE);
OneWire oneWire(ONE_WIRE_BUS);
DallasTemperature sensors(&oneWire);
Adafruit_ADS1115 ads;
RTC_DS3231 rtc;
WiFiClient espClient;
PubSubClient client(espClient);

// Deklarasi Bluetooth Serial
BluetoothSerial SerialBT;  // Objek Bluetooth Serial

// Deklarasi Variabel Global
float tdsValue = 0;
float temperatureWater = 0;
float temperature = 0;
float humidity = 0;

//========================== Fungsi Inisialisasi Bluetooth Serial ==========================

void bluetoothSetup() {
  SerialBT.begin("Hera_TDS");  // Inisialisasi Bluetooth dengan nama perangkat
  Serial.println("Bluetooth Serial dimulai...");

  // Tunggu hingga perangkat Bluetooth terhubung
  while (!SerialBT.hasClient()) {
    delay(500);
    Serial.println("Menunggu koneksi Bluetooth...");
  }
  Serial.println("Perangkat Bluetooth terhubung.");

  // Cek koneksi setiap 5 detik dan coba sambungkan kembali jika terputus
  while (true) {
    if (!SerialBT.hasClient()) {
      Serial.println("Bluetooth terputus, mencoba untuk menyambung kembali...");
      SerialBT.begin("Hera_TDS");
      while (!SerialBT.hasClient()) {
        delay(500);
        Serial.println("Menunggu koneksi Bluetooth...");
      }
      Serial.println("Perangkat Bluetooth terhubung kembali.");
    }
    delay(5000);  // Cek koneksi setiap 5 detik
  }
}

/*========================== Fungsi Inisialisasi Wifi ==========================*/

void wifiSetup() {
  WiFi.begin(ssid, password);
  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
    Serial.print(".");
  }
  Serial.println("\nWiFi Terhubung");
  Serial.print("IP Address: ");
  Serial.println(WiFi.localIP());
}

/*========================== Fungsi Inisialisasi MQTT ==========================*/

void mqttSetup() {
  while (!client.connected()) {
    Serial.print("Menghubungkan ke MQTT...");
    String clientId = "ESP32Client-" + String(random(0xffff), HEX);
    
    if (client.connect(clientId.c_str(), mqtt_username, mqtt_password)) {
      Serial.println("terhubung ke MQTT");
      client.subscribe(topic);
    } else {
      Serial.print("gagal, rc=");
      Serial.print(client.state());
      Serial.println(" mencoba lagi dalam 5 detik");
      delay(5000);
    }
  }
}

//========================== Fungsi Pembacaan Sensor ==========================

// SENSOR TEMPERATURE DS18B20
void readWaterTemperature() {
  sensors.requestTemperatures();
  temperatureWater = sensors.getTempCByIndex(0);
    
  if (temperatureWater == DEVICE_DISCONNECTED_C) { // Jika sensor tidak terhubung
    temperatureWater = 0.0; // Nilai default
    Serial.println("Sensor DS18B20 tidak terhubung! Menggunakan nilai default.");
  } 
  else {
    Serial.print("Suhu Air: ");
    Serial.print(temperatureWater);
    Serial.println("°C");
  }
}

// TDS SENSOR
void readTDSSensor() {
    int16_t adcValue = ads.readADC_SingleEnded(TDS_SENSOR_CHANNEL);
    if(adcValue == -1) {
      tdsValue = 0;
      Serial.println("Gagal membaca sensor TDS.");
      return;
    }

    //Fungsi Perhitungan Nilai TDS
    float voltage = (adcValue * ADC_REF_VOLTAGE) / ADC_MAX; // Konversi ke voltase (3.3V)
    float compensationFactor = 1.0 + 0.02 * (temperatureWater - DEFAULT_WATER_TEMP); // Faktor kompensasi suhu
    float tds = (133.42 * voltage * voltage * voltage - 255.86 * voltage * voltage + 857.39 * voltage) * compensationFactor;
    tdsValue = tds;

    Serial.print("TDS: ");
    Serial.print(tdsValue);
    Serial.println(" ppm");
}

// DHT22 SENSOR
void readDHTSensor() {
  humidity = dht.readHumidity();
  temperature = dht.readTemperature();

  if (isnan(humidity) || isnan(temperature)) { // Jika pembacaan gagal
    humidity = 0.0;    // Nilai default kelembapan
    temperature = 0.0; // Nilai default suhu
    Serial.println("Gagal membaca DHT22! Menggunakan nilai default.");
  } 
  else {
    Serial.print("Suhu Udara: ");
    Serial.print(temperature);
    Serial.print("°C, Kelembapan: ");
    Serial.print(humidity);
    Serial.println("%");
 }
}

/*========================== Fungsi Pengiriman Data Ke Bluetooth dan MQTT ==========================*/

void kirimBluetoothSerial() {
  // Baca data dari sensor
  readWaterTemperature();   // Baca data sensor DS18B20
  readTDSSensor();          // Baca data sensor TDS
  readDHTSensor();          // Baca data sensor DHT22

  // Tampilkan data ke Bluetooth Serial
  SerialBT.print("Suhu Air: ");
  SerialBT.print(temperatureWater);
  SerialBT.print("°C, ");
  SerialBT.print("TDS: ");
  SerialBT.print(tdsValue);
  Serial.println(" ppm");
  SerialBT.print("Suhu Udara: ");
  SerialBT.print(temperature);
  SerialBT.print("°C, ");
  SerialBT.print("Kelembapan: ");
  SerialBT.print(humidity);
  SerialBT.println("%");

  // Kirim data ke MQTT
  StaticJsonDocument<200> doc;
  doc["Suhu Air"] = temperatureWater;
  doc["TDS"] = tdsValue;
  doc["Suhu Lingkungan"] = temperature;
  doc["Kelembapan Lingkungan"] = humidity;
  char buffer[256];
  serializeJson(doc, buffer);
  
  if (client.publish(topic, buffer)) {
    Serial.println("Data berhasil dikirim ke MQTT.");
  } else {
    Serial.println("Gagal mengirim data ke MQTT.");
    if (!client.connected()) {
      mqttSetup();
    }
  }
}

/*========================== Fungsi Setup ==========================*/
void setup() {
  Serial.begin(115200);
  bluetoothSetup();  // Setup Bluetooth
  wifiSetup();       // Setup WiFi
  mqttSetup();       // Setup MQTT
  
  // Inisialisasi sensor
  dht.begin();
  sensors.begin();
  ads.begin();
  rtc.begin();

  Serial.println("Semua perangkat terhubung!");
  delay(1000);
}

void loop() {
  kirimBluetoothSerial();  // Kirim data ke Bluetooth Serial dan MQTT
  delay(5000);  // Tunggu 5 detik
}
