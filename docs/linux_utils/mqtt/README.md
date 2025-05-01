# MQTT on Linux
It's often handy to be able to host an MQTT broker on a Linux machine, or publish/subscribe to a
topic when doing MQTT development. A package called `mostquitto` makes it easy.

# Set Up a Broker
1. Install `mosquitto` and `mosquitto-clients`.
   ```
   sudo apt update
   sudo apt install mosquitto mosquitto-clients
   ```
2. Enable and start `mosquitto`.
   ```
   sudo systemctl enable mosquitto
   sudo systemctl start mosquitto
   ```
3. Allow remote connections by appending the following line to `/etc/mosquitto/mosquitto.conf`.
   ```
   listener 1883
   allow_anonymous true
   ```
4. If a firewall is active, allow access on port 1883.
   ```
   sudo ufw allow 1883
   ```
5. Verify broker is working by subscribing some arbitrary topic name (e.g. `test`) and publishing
   to that topic.
   - `-h`: host IP
   - `-t`: topic string
   - `-m`: message string
   - `-v`: verbose flag, print topic and message
   - `&` : run subscribe command in background so publish command runs

   ```
   mosquitto_sub -h localhost -t test -v &
   mosquitto_sub -h localhost -t test -m "Hello from broker device!"
   ```

# Set Up a Client
1. Install `mosquitto` and `mosquitto-clients`.
   ```
   sudo apt update
   sudo apt install mosquitto-clients
   ```
2. Connect client computer to same network as that hosting the broker.
3. Verify client is working by publishing to some arbitrary topic name (e.g. `test`) and ensuring
   it is received by subscribers.
   ```
   # On some other client/broker device
   mosquitto_sub -h localhost -t test -v

   # On client device
   BROKER_IP="10.0.0.150"
   mosquitto_pub -h $BROKER_IP -t test -m "Hello from client device!"
   ```
4 . You can also check to ensure the client can subscribe to topics by subscribing to some topic on
    the client device, and publishing from the broker device.
       ```
   # On client device
   BROKER_IP="10.0.0.150"
   mosquitto_sub -h $BROKER_IP -t test -v

   # On some other client/broker device
   mosquitto_pub -h localhost -t test -m "Hello from client device!"
   ```
