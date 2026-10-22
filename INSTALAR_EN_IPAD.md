# Cómo instalar Confeti en un iPad

Necesitas una Mac, el cable del iPad y un Apple ID (el de siempre sirve). El iPad debe tener iPadOS 17 o más nuevo.

## Una sola vez

1. Instala **Xcode** desde la App Store (es gratis; tarda porque pesa mucho). Si la App Store no te deja, primero actualiza macOS.
2. Abre Xcode. Si te pide instalar componentes, dale **Install** y marca **iOS**.
3. En Xcode: menú **Xcode › Settings › Accounts › +** › Apple ID, y entra con tu cuenta.
4. Descarga el proyecto de GitHub (**Code › Download ZIP**) y descomprímelo.
5. Abre `Confeti.xcodeproj` con doble clic.
6. En la columna izquierda, haz clic en el icono azul **Confeti** (hasta arriba). En el centro, entra a la pestaña **Signing & Capabilities** y en **Team** elige tu nombre (*Personal Team*).
   - Si sale un error rojo que menciona *bundle identifier*, en **Bundle Identifier** cambia `com.tecmilenio.Confeti` por `com.tunombre.confeti`.

## Por cada iPad

1. Conecta el iPad con el cable. En el iPad sale "¿Confiar en esta computadora?": toca **Confiar**.
2. En el iPad: **Ajustes › Privacidad y seguridad › Modo de desarrollador**, actívalo y deja que se reinicie. (La opción aparece después de conectarlo a la Mac con Xcode abierto.)
3. En Xcode, arriba al centro, elige el iPad en la lista de dispositivos y dale **▶** (o ⌘R). La primera vez tarda unos minutos.
4. Si en el iPad sale "Desarrollador no confiable": **Ajustes › General › VPN y gestión de dispositivos ›** tu Apple ID **› Confiar**. Abre Confeti otra vez.

## Bueno saber

- Con un Apple ID gratis la app deja de abrir a los **7 días**. Para renovarla conecta el iPad y dale ▶ otra vez; los jugadores y sus estrellas no se borran.
- Para probarla sin iPad, en la lista de dispositivos elige un simulador de iPad y dale ▶.
- Si aparece algo en rojo que no esté aquí, toma captura y mándasela a Darío.
