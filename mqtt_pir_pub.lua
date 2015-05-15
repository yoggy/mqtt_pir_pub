-- load configuration
require("config")

-- pin assign
-- https://github.com/nodemcu/nodemcu-firmware/wiki/nodemcu_api_en#new_gpio_map

-- setup gpio
led_pin = 3 -- GPIO0
input_pin = 4 -- GPIO2
gpio.mode(led_pin, gpio.OUTPUT)
gpio.mode(input_pin, gpio.INPUT)

tmr.delay(1000 * 1000)

-- wifi
print("connect to ssid=" .. wifi_ssid);

wifi.setmode(wifi.STATION)
wifi.sta.config(wifi_ssid, wifi_pass)

for i = 1, 10 do
  gpio.write(led_pin, gpio.LOW);
  tmr.delay(1000 * 1000)
  if wifi.sta.status() == 5 then
    break
  end
  print(i);
  if i == 20 then
    print("wifi connecting failed...rebooting");
    node.restart();
    tmr.delay(5000 * 1000)
  end
  
  print("wifi connection waiting...");
  gpio.write(led_pin, gpio.HIGH);
  tmr.delay(1000 * 1000)
end

print("wifi connected!");
print(wifi.sta.getip());
gpio.write(led_pin, gpio.HIGH);

-- publish
pub_sem = 0
function publish_pir(val)
    if pub_sem == 0 then
        pub_sem = 1
        pub_msg = "{\"pir\":" .. val .. ",\"tickcount\":" .. tmr.time() .. "}";
        print(pub_msg)
        m:publish(mqtt_publish_topic, pub_msg, 0, 0, function(conn) 
            pub_sem = 0
        end)
    end  
end

function main_func()
    val = gpio.read(input_pin)
    publish_pir(val)
    tmr.alarm(5, 1000, 0, main_func)
end

-- MQTT
-- see also... http://www.nodemcu.com/docs/mqtt-module/
m = mqtt.Client(mqtt_client_id, 60, mqtt_username, mqtt_password)

m:on("offline", function(con) print ("offline...rebooting");  node.restart(); tmr.delay(5000 * 1000)end)
print("mqtt:connect() start")
m:connect(mqtt_host, mqtt_port, 0, function(conn)
    print("connected")
    tmr.alarm(5, 1000, 0, main_func)
end)
  


