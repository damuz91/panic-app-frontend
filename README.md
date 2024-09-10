# Botón de pánico

Aplicación de botón de Pánico, creada por David Muñoz para el canal [EstoyProgramando](https://www.youtube.com/c/estoyprogramando)

## Acerca de
Este proyecto creado en Flutter es parte de una serie de aplicaciones que creé a manera de demostración para las listas de reproducción de cómo crear aplicaciones que moneticen.

https://www.youtube.com/playlist?list=PLKdf6-2FoMDRhoHmKPxpU2iIWMAVNiOq-

Para ver el repositorio del backend: https://github.com/damuz91/panic-backend

## Aplicación

No soy un experto en flutter, de hecho esta aplicación la creé usando ChatGPT.
El código fuente está en la carpeta lib y los archivos con los parámetros de configuración como la URL del backend, la api key que se envía al backend y otros se encuentran en la carpeta assets.

Para correr el proyecto se requiere el backend corriendo y los puertos habilitados para tener conexiones en la red local. Modifique el contenido de los archivos de la carpeta assets como corresponda.

Para el almacenamiento de datos en la app uso SQlite y el SharedPreferences.

En la carpeta assets hay 2 archivos: `api_key.txt` y `backend_url.txt`, se deben modificar de acuerdo a la api_key que esté en el backend y a la url del backend, sea en local o producción. 
La verdad no encontré donde colocar los parámetros sin necesidad de subirlos al repositorio, algo como las credenciales, o los secretos, entonces utilizo este mecanismo trivial para guardar los 'secretos', aunque no lo son porque se puede decompilar el paquete final para poder ver los valores, no lo mencionen. 

## Despliegue

Para desplegar la aplicación recomiendo los siguientes videos:
https://www.youtube.com/watch?v=0zgDF81ZLrQ&ab_channel=HeyFlutter%E2%80%A4com
https://www.youtube.com/watch?v=g0GNuoCOtaQ&ab_channel=HeyFlutter%E2%80%A4com

Se debe generar el upload-keystore.jks el cual agregué al .gitignore