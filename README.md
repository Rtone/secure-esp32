# Secure ESP32
---------

**Secure ESP32** is an entry point for Espressif development ESP32 platforms and a part of a larger project for best practice recommended for IoT firmwares security.         
It focuses on maintaining different security parts of the network protocols used to foster good practice and awareness of security weaknesses and point to components that needfurther hardening.


All developments have been conducted on an ESP32 ESPRESSIF development kit platform:

*   The currently supported ESP32 development board is: **ESP-WROOM-32 DEVKIT-V1**
*   The currently supported features are: **WiFi, BT, Dual Core, 240MHz, VRef calibration in efuse, Coding Scheme None**
*   The currently supported chip version is: **ESP32D0WDQ6**
*   The currently supported host operating system is: **Linux 64-bit**

The project may need modifications to work with other versions or other boards.

[![asciicast](https://asciinema.org/a/TUVugHeSFMdA6UpvxQLRJh28d.svg)](https://asciinema.org/a/TUVugHeSFMdA6UpvxQLRJh28d)

## Supported Features 

This current version supports the following features :

- [x]	Automated script to set up the Espressif *development environment*, increase *entropy* when generating keys and generate *Flash Encryption* and *Secure Boot Signing Keys*.    
- [x]	Main set up for the *Flash Encryption* mode.  
- [x]	Build chains of trust certificate used for *TLS layer*, check the [Certificate Management](./certs_manager) submodule.  
- [x]	Wifi Access Point task.  
- [x]	HTTPS Requests task with TLS layer.
- [x]	MQTT Client task with TLS layer.

## TODO Feature List

- [ ]	Add more network and IoT communication protocols. 
- [ ]	Implement end-to-end encryption for better  defense-in-depth against TLS limitation (when the service itself is compromised) and to avoid data breaches.     


## Contributions or Need Help 

You are welcome to contribute and suggest any improvements.
If you want to point to an issue, Please [file an issue](https://github.com/Rtone/secure-esp32/issues).


If you have questions or need further guidance on using the tool, 
Please [file an issue](https://github.com/Rtone/secure-esp32/issues).

 
## Direct contributions

Fork the repository, file a pull request and You are good to go ;)


## License

This project is licensed under The MIT License terms.

Copyright (c) 2019 Rtone IoT Security

