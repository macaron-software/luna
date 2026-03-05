#!/usr/bin/env python3
"""
Generates README_XX.md for all 40 LUNA languages.
Each file: title, strong privacy pledge (9 points), "never do" table, screenshots, architecture.
Run: python3 scripts/gen_readme_translations.py
"""
import os

BACK = "../../README.md"
OUT_DIR = os.path.join(os.path.dirname(__file__), "../docs/i18n")
os.makedirs(OUT_DIR, exist_ok=True)

# Each entry: (code, flag, lang_native, tagline, pledge9[9], never_title, never_rows[7], arch_title, arch_desc, note)
# pledge9: 9 rows of (icon, text) — cover: server, offline, account, sdk, encryption, backup, telemetry, wipe, opensource
LANGS = [

("FR","🇫🇷","Français",
"Votre cycle. Votre téléphone. Aucun serveur. Aucun cloud. Zéro compromis.",
[("📵","**Aucun serveur.** Nous n'en avons pas. Pas de backend, pas de base de données distante, aucun point d'API auquel l'application se connecte."),
 ("📶","**Fonctionne 100 % hors ligne.** Aucune connexion internet n'est jamais requise ou utilisée. Installez une fois, utilisez à vie sans réseau."),
 ("🚷","**Aucun compte, aucune inscription.** Pas d'e-mail, pas de mot de passe, pas de connexion sociale, pas de vérification d'identité. Rien."),
 ("🧩","**Aucune dépendance à un service tiers.** Pas de Firebase, pas de Google Analytics, pas de Mixpanel, pas de Sentry, pas d'Amplitude. Zéro SDK externe."),
 ("🔐","**Données chiffrées sur votre téléphone uniquement.** Base SQLCipher chiffrée AES-256-GCM. Clé dérivée de votre PIN via Argon2id. La clé ne quitte jamais l'appareil."),
 ("☁️","**Sauvegarde cloud optionnelle — entièrement chiffrée.** iCloud/Google Drive reçoit un blob chiffré opaque. Même Apple et Google ne peuvent pas le lire."),
 ("🚫","**Zéro télémétrie, zéro analytique.** Aucun rapport de crash, aucune métrique d'usage, aucun flag de fonctionnalité, aucun A/B test. Rien ne quitte votre téléphone."),
 ("💥","**Effacement panique en 3 secondes.** Maintenez le bouton : base de données + sel + toutes les clés cryptographiques sont détruites de manière irréversible."),
 ("🔓","**100 % open source.** MIT/Apache-2.0. Chaque ligne de code est publique et auditable par quiconque.")],
"Ce que LUNA ne fera JAMAIS",
[("Aucun serveur","Nous n'en avons pas. Impossible d'envoyer vos données quelque part."),
 ("Aucun internet requis","L'application fonctionne 100 % hors ligne. Toujours."),
 ("Aucun compte","Pas d'email, pas de mot de passe, pas de connexion."),
 ("Aucune vente de données","Impossible — nous ne les recevons jamais."),
 ("Aucune pub","Zéro SDK publicitaire, zéro pixel de tracking."),
 ("Aucune télémétrie push","Les rappels utilisent uniquement le système OS — aucune donnée ne transite par un serveur."),
 ("Aucun SDK caché","Le binaire ne contient que ce que vous voyez dans ce dépôt.")],
"Architecture","Noyau Rust partagé (UniFFI) · SwiftUI iOS · Kotlin Android · SQLCipher chiffré · zéro réseau",
"⚠️ Cette application ne fournit pas de conseil médical."),

("DE","🇩🇪","Deutsch",
"Ihr Zyklus. Ihr Telefon. Kein Server. Keine Cloud. Kein Kompromiss.",
[("📵","**Kein Server.** Wir haben keinen. Kein Backend, keine Remote-Datenbank, kein API-Endpunkt, den die App aufruft."),
 ("📶","**Funktioniert 100 % offline.** Es wird nie eine Internetverbindung benötigt oder genutzt. Einmal installieren, ewig ohne Netz nutzen."),
 ("🚷","**Kein Konto, keine Registrierung.** Keine E-Mail, kein Passwort, kein Social-Login, keine Identitätsprüfung. Nichts."),
 ("🧩","**Keine Abhängigkeit von Drittanbieterdiensten.** Kein Firebase, kein Google Analytics, kein Mixpanel, kein Sentry, kein Amplitude. Null externe SDKs."),
 ("🔐","**Verschlüsselte Daten nur auf Ihrem Telefon.** SQLCipher-Datenbank mit AES-256-GCM. Schlüssel via Argon2id aus Ihrer PIN. Der Schlüssel verlässt das Gerät nie."),
 ("☁️","**Optionales Cloud-Backup — vollständig verschlüsselt.** iCloud/Google Drive empfängt ein opakes verschlüsseltes Blob. Selbst Apple und Google können es nicht lesen."),
 ("🚫","**Null Telemetrie, null Analytics.** Keine Crash-Berichte, keine Nutzungsmetriken, kein A/B-Testing. Nichts verlässt Ihr Telefon."),
 ("💥","**Panik-Wipe in 3 Sekunden.** Taste gedrückt halten: Datenbank + Salt + alle Schlüssel werden unwiderruflich gelöscht."),
 ("🔓","**100 % Open Source.** MIT/Apache-2.0. Jede Codezeile ist öffentlich und für jeden auditierbar.")],
"Was LUNA NIEMALS tun wird",
[("Kein Server","Wir haben keinen. Unmöglich, Ihre Daten irgendwohin zu senden."),
 ("Kein Internet nötig","Die App funktioniert 100 % offline. Immer."),
 ("Kein Konto","Keine E-Mail, kein Passwort, keine Anmeldung."),
 ("Kein Datenverkauf","Unmöglich — wir empfangen sie nie."),
 ("Keine Werbung","Null Werbe-SDK, null Tracking-Pixel."),
 ("Keine Push-Telemetrie","Erinnerungen nutzen nur das OS-System — keine Daten über Server."),
 ("Kein verstecktes SDK","Das Binary enthält nur, was Sie in diesem Repository sehen.")],
"Architektur","Gemeinsamer Rust-Kern (UniFFI) · SwiftUI iOS · Kotlin Android · SQLCipher verschlüsselt · kein Netzwerk",
"⚠️ Diese App bietet keine medizinische Beratung."),

("ES","🇪🇸","Español",
"Tu ciclo. Tu teléfono. Ningún servidor. Ninguna nube. Cero compromisos.",
[("📵","**Ningún servidor.** No tenemos ninguno. Sin backend, sin base de datos remota, sin punto de API al que la app se conecte."),
 ("📶","**Funciona 100% sin conexión.** Nunca se requiere ni se usa conexión a internet. Instala una vez, usa siempre sin red."),
 ("🚷","**Sin cuenta, sin registro.** Sin email, sin contraseña, sin login social, sin verificación de identidad. Nada."),
 ("🧩","**Sin dependencia de servicios de terceros.** Sin Firebase, sin Google Analytics, sin Mixpanel, sin Sentry, sin Amplitude. Cero SDKs externos."),
 ("🔐","**Datos cifrados solo en tu teléfono.** Base de datos SQLCipher cifrada con AES-256-GCM. Clave derivada de tu PIN via Argon2id. La clave nunca sale del dispositivo."),
 ("☁️","**Copia de seguridad cloud opcional — completamente cifrada.** iCloud/Google Drive recibe un blob cifrado opaco. Ni Apple ni Google pueden leerlo."),
 ("🚫","**Cero telemetría, cero analítica.** Sin informes de fallos, sin métricas de uso, sin pruebas A/B. Nada sale de tu teléfono."),
 ("💥","**Borrado de pánico en 3 segundos.** Mantén el botón: base de datos + sal + todas las claves criptográficas se destruyen irreversiblemente."),
 ("🔓","**100% código abierto.** MIT/Apache-2.0. Cada línea de código es pública y auditable por cualquiera.")],
"Lo que LUNA NUNCA hará",
[("Sin servidor","No tenemos ninguno. Imposible enviar tus datos a ningún lado."),
 ("Sin internet requerido","La app funciona 100% offline. Siempre."),
 ("Sin cuenta","Sin email, sin contraseña, sin login."),
 ("Sin venta de datos","Imposible — nunca los recibimos."),
 ("Sin publicidad","Cero SDK publicitario, cero píxel de seguimiento."),
 ("Sin telemetría push","Los recordatorios usan solo el sistema OS — sin datos por servidor."),
 ("Sin SDK oculto","El binario contiene solo lo que ves en este repositorio.")],
"Arquitectura","Núcleo Rust compartido (UniFFI) · SwiftUI iOS · Kotlin Android · SQLCipher cifrado · cero red",
"⚠️ Esta aplicación no ofrece consejo médico."),

("AR","🇦🇪","العربية",
"دورتك. هاتفك. لا خادم. لا سحابة. لا تنازلات.",
[("📵","**لا خادم على الإطلاق.** ليس لدينا خادم. لا backend، لا قاعدة بيانات بعيدة، لا نقطة API تتصل بها التطبيقة."),
 ("📶","**يعمل 100% بدون إنترنت.** لا يُستخدم اتصال بالإنترنت أبدًا ولا يُطلب. ثبّت مرة واحدة، استخدم للأبد بدون شبكة."),
 ("🚷","**لا حساب، لا تسجيل.** لا بريد إلكتروني، لا كلمة مرور، لا تسجيل دخول اجتماعي، لا التحقق من الهوية. لا شيء."),
 ("🧩","**لا اعتماد على خدمات طرف ثالث.** لا Firebase، لا Google Analytics، لا Mixpanel، لا Sentry، لا Amplitude. صفر SDK خارجي."),
 ("🔐","**البيانات مشفرة على هاتفك فقط.** قاعدة بيانات SQLCipher مشفرة بـ AES-256-GCM. المفتاح مشتق من رمز PIN عبر Argon2id. لا يغادر المفتاح الجهاز أبدًا."),
 ("☁️","**نسخ احتياطي اختياري في السحابة — مشفر تمامًا.** iCloud/Google Drive يستقبل كتلة مشفرة غير شفافة. حتى Apple وGoogle لا يستطيعان قراءتها."),
 ("🚫","**صفر قياس أداء، صفر تحليلات.** لا تقارير أعطال، لا مقاييس استخدام، لا اختبارات A/B. لا شيء يغادر هاتفك."),
 ("💥","**محو الذعر في 3 ثوانٍ.** اضغط مطولًا على الزر: قاعدة البيانات + الملح + جميع المفاتيح التشفيرية تُتلف بشكل لا رجعة فيه."),
 ("🔓","**100% مفتوح المصدر.** MIT/Apache-2.0. كل سطر كود علني وقابل للمراجعة من قبل أي شخص.")],
"ما لن تفعله LUNA أبدًا",
[("لا خادم","ليس لدينا. مستحيل إرسال بياناتك إلى أي مكان."),
 ("لا إنترنت مطلوب","التطبيق يعمل 100% بدون شبكة. دائمًا."),
 ("لا حساب","لا بريد، لا كلمة مرور، لا تسجيل دخول."),
 ("لا بيع للبيانات","مستحيل — لا نستقبلها أبدًا."),
 ("لا إعلانات","صفر SDK إعلاني، صفر بكسل تتبع."),
 ("لا قياس Push","التذكيرات تستخدم نظام OS فقط — بدون بيانات عبر أي خادم."),
 ("لا SDK مخفي","البرنامج الثنائي يحتوي فقط على ما تراه في هذا المستودع.")],
"البنية التقنية","نواة Rust مشتركة (UniFFI) · SwiftUI iOS · Kotlin Android · SQLCipher مشفّر · صفر شبكة",
"⚠️ هذا التطبيق لا يقدم استشارات طبية."),

("JA","🇯🇵","日本語",
"あなたのサイクル。あなたの電話。サーバーなし。クラウドなし。妥協なし。",
[("📵","**サーバーなし。** 私たちはサーバーを持っていません。バックエンドなし、リモートデータベースなし、アプリが接続するAPIエンドポイントなし。"),
 ("📶","**100% オフラインで動作。** インターネット接続は一切不要で使用もされません。一度インストールすれば、ネットワークなしで永遠に使えます。"),
 ("🚷","**アカウント不要、登録不要。** メールアドレス不要、パスワード不要、ソーシャルログイン不要、本人確認不要。何も不要。"),
 ("🧩","**サードパーティサービスへの依存なし。** Firebase、Google Analytics、Mixpanel、Sentry、Amplitudeは一切使用しません。外部SDKはゼロ。"),
 ("🔐","**データはあなたの電話にのみ暗号化保存。** AES-256-GCMで暗号化されたSQLCipherデータベース。Argon2idでPINから派生したキー。キーはデバイスから外に出ません。"),
 ("☁️","**オプションのクラウドバックアップ — 完全暗号化。** iCloud/Google Driveには不透明な暗号化ブロブが送られます。AppleもGoogleも読めません。"),
 ("🚫","**テレメトリーゼロ、分析ゼロ。** クラッシュレポートなし、使用統計なし、A/Bテストなし。何もあなたの電話を離れません。"),
 ("💥","**3秒でパニックワイプ。** ボタンを長押し：データベース + ソルト + すべての暗号鍵が不可逆的に破壊されます。"),
 ("🔓","**100% オープンソース。** MIT/Apache-2.0。すべてのコード行が公開されており、誰でも監査できます。")],
"LUNAが絶対にしないこと",
[("サーバーなし","私たちはサーバーを持っていません。データを送る場所がありません。"),
 ("インターネット不要","アプリは100% オフラインで動作します。常に。"),
 ("アカウントなし","メールなし、パスワードなし、ログインなし。"),
 ("データ売却なし","不可能 — 私たちはデータを受け取りません。"),
 ("広告なし","広告SDKゼロ、トラッキングピクセルゼロ。"),
 ("Pushテレメトリーなし","リマインダーはOSシステムのみ使用 — サーバー経由のデータなし。"),
 ("隠しSDKなし","バイナリにはこのリポジトリで見るものだけが含まれています。")],
"アーキテクチャ","共有Rustコア (UniFFI) · SwiftUI iOS · Kotlin Android · SQLCipher暗号化 · ゼロネットワーク",
"⚠️ このアプリは医療アドバイスを提供しません。"),

("ZH-Hans","🇨🇳","简体中文",
"您的周期。您的手机。无服务器。无云端。零妥协。",
[("📵","**无服务器。** 我们没有服务器。无后端，无远程数据库，无应用连接的API端点。"),
 ("📶","**100% 离线运行。** 从不需要或使用互联网连接。安装一次，无需网络永久使用。"),
 ("🚷","**无账户，无注册。** 无电子邮件，无密码，无社交登录，无身份验证。什么都不需要。"),
 ("🧩","**不依赖任何第三方服务。** 无Firebase，无Google Analytics，无Mixpanel，无Sentry，无Amplitude。零外部SDK。"),
 ("🔐","**数据仅加密存储在您的手机上。** AES-256-GCM加密的SQLCipher数据库。通过Argon2id从PIN派生密钥。密钥永不离开设备。"),
 ("☁️","**可选云备份——完全加密。** iCloud/Google Drive收到不透明的加密数据块。即使Apple和Google也无法读取。"),
 ("🚫","**零遥测，零分析。** 无崩溃报告，无使用指标，无A/B测试。没有任何东西离开您的手机。"),
 ("💥","**3秒紧急清除。** 长按按钮：数据库+盐+所有加密密钥不可逆地销毁。"),
 ("🔓","**100% 开源。** MIT/Apache-2.0。每一行代码都是公开的，任何人都可以审计。")],
"LUNA绝对不会做的事",
[("无服务器","我们没有。不可能把您的数据发送到任何地方。"),
 ("无需互联网","应用100% 离线运行。始终如此。"),
 ("无账户","无邮件，无密码，无登录。"),
 ("不出售数据","不可能——我们从不接收数据。"),
 ("无广告","零广告SDK，零追踪像素。"),
 ("无Push遥测","提醒仅使用OS系统——无数据通过服务器。"),
 ("无隐藏SDK","二进制文件只包含您在此仓库中看到的内容。")],
"架构","共享Rust核心 (UniFFI) · SwiftUI iOS · Kotlin Android · SQLCipher加密 · 零网络",
"⚠️ 本应用不提供医疗建议。"),

("ZH-Hant","🇹🇼","繁體中文",
"您的週期。您的手機。無伺服器。無雲端。零妥協。",
[("📵","**無伺服器。** 我們沒有伺服器。無後端，無遠端資料庫，無應用程式連接的API端點。"),
 ("📶","**100% 離線運作。** 從不需要或使用網路連線。安裝一次，無需網路永久使用。"),
 ("🚷","**無帳戶，無註冊。** 無電子郵件，無密碼，無社交登入，無身份驗證。什麼都不需要。"),
 ("🧩","**不依賴任何第三方服務。** 無Firebase，無Google Analytics，無Mixpanel，無Sentry。零外部SDK。"),
 ("🔐","**資料僅加密存儲在您的手機上。** AES-256-GCM加密的SQLCipher資料庫。密鑰永不離開裝置。"),
 ("☁️","**可選雲端備份——完全加密。** iCloud/Google Drive收到不透明的加密數據塊。即使Apple和Google也無法讀取。"),
 ("🚫","**零遙測，零分析。** 沒有任何東西離開您的手機。"),
 ("💥","**3秒緊急清除。** 長按按鈕：資料庫+鹽+所有加密密鑰不可逆地銷毀。"),
 ("🔓","**100% 開源。** MIT/Apache-2.0。每一行程式碼都是公開的，任何人都可以審計。")],
"LUNA絕對不會做的事",
[("無伺服器","我們沒有。不可能把您的數據發送到任何地方。"),
 ("無需網路","應用100% 離線運作。"),
 ("無帳戶","無郵件，無密碼，無登入。"),
 ("不出售數據","不可能——我們從不接收數據。"),
 ("無廣告","零廣告SDK，零追蹤像素。"),
 ("無Push遙測","提醒僅使用OS系統。"),
 ("無隱藏SDK","二進位檔案只包含您在此儲存庫中看到的內容。")],
"架構","共享Rust核心 (UniFFI) · SwiftUI iOS · Kotlin Android · SQLCipher加密 · 零網路",
"⚠️ 本應用程式不提供醫療建議。"),

("PT-BR","🇧🇷","Português BR",
"Seu ciclo. Seu telefone. Nenhum servidor. Nenhuma nuvem. Zero compromisso.",
[("📵","**Nenhum servidor.** Não temos nenhum. Sem backend, sem banco de dados remoto, nenhum endpoint de API que o app usa."),
 ("📶","**Funciona 100% offline.** Nenhuma conexão com a internet é jamais necessária ou usada. Instale uma vez, use para sempre sem rede."),
 ("🚷","**Sem conta, sem cadastro.** Sem e-mail, sem senha, sem login social, sem verificação de identidade. Nada."),
 ("🧩","**Sem dependência de serviços de terceiros.** Sem Firebase, sem Google Analytics, sem Mixpanel, sem Sentry, sem Amplitude. Zero SDKs externos."),
 ("🔐","**Dados criptografados apenas no seu telefone.** Banco de dados SQLCipher criptografado com AES-256-GCM. Chave derivada do seu PIN via Argon2id. A chave nunca sai do dispositivo."),
 ("☁️","**Backup em nuvem opcional — totalmente criptografado.** iCloud/Google Drive recebe um blob criptografado opaco. Nem Apple nem Google conseguem lê-lo."),
 ("🚫","**Zero telemetria, zero analytics.** Sem relatórios de falha, sem métricas de uso, sem testes A/B. Nada sai do seu telefone."),
 ("💥","**Apagamento de pânico em 3 segundos.** Segure o botão: banco de dados + sal + todas as chaves criptográficas são destruídas irreversivelmente."),
 ("🔓","**100% código aberto.** MIT/Apache-2.0. Cada linha de código é pública e auditável por qualquer pessoa.")],
"O que a LUNA NUNCA fará",
[("Nenhum servidor","Não temos. Impossível enviar seus dados para qualquer lugar."),
 ("Sem internet necessária","O app funciona 100% offline. Sempre."),
 ("Sem conta","Sem e-mail, sem senha, sem login."),
 ("Sem venda de dados","Impossível — nunca os recebemos."),
 ("Sem anúncios","Zero SDK de publicidade, zero pixel de rastreamento."),
 ("Sem telemetria push","Lembretes usam apenas o sistema OS — sem dados por servidor."),
 ("Sem SDK oculto","O binário contém apenas o que você vê neste repositório.")],
"Arquitetura","Núcleo Rust compartilhado (UniFFI) · SwiftUI iOS · Kotlin Android · SQLCipher criptografado · zero rede",
"⚠️ Este aplicativo não fornece conselho médico."),

("RU","🇷🇺","Русский",
"Ваш цикл. Ваш телефон. Никаких серверов. Никаких облаков. Никаких компромиссов.",
[("📵","**Никаких серверов.** У нас их нет. Никакого бэкенда, никакой удалённой базы данных, никаких API-эндпоинтов."),
 ("📶","**Работает 100% офлайн.** Интернет-соединение никогда не требуется и не используется. Установите один раз — используйте вечно без сети."),
 ("🚷","**Никаких аккаунтов, никакой регистрации.** Никакого email, никакого пароля, никакого входа через соцсети, никакой верификации."),
 ("🧩","**Никакой зависимости от сторонних сервисов.** Никакого Firebase, Google Analytics, Mixpanel, Sentry, Amplitude. Ноль внешних SDK."),
 ("🔐","**Данные зашифрованы только на вашем телефоне.** База данных SQLCipher с AES-256-GCM. Ключ выводится из PIN через Argon2id. Ключ никогда не покидает устройство."),
 ("☁️","**Необязательное облачное резервное копирование — полностью зашифровано.** iCloud/Google Drive получает непрозрачный зашифрованный блоб. Даже Apple и Google не могут его прочитать."),
 ("🚫","**Ноль телеметрии, ноль аналитики.** Никаких отчётов о сбоях, никаких метрик использования, никакого A/B-тестирования. Ничто не покидает ваш телефон."),
 ("💥","**Паническое удаление за 3 секунды.** Удерживайте кнопку: база данных + соль + все криптографические ключи уничтожаются необратимо."),
 ("🔓","**100% открытый исходный код.** MIT/Apache-2.0. Каждая строка кода публична и доступна для аудита.")],
"Что LUNA НИКОГДА не будет делать",
[("Никаких серверов","У нас нет. Невозможно отправить ваши данные куда-либо."),
 ("Без интернета","Приложение работает 100% офлайн. Всегда."),
 ("Без аккаунта","Без email, без пароля, без входа."),
 ("Без продажи данных","Невозможно — мы их никогда не получаем."),
 ("Без рекламы","Ноль рекламных SDK, ноль пикселей отслеживания."),
 ("Без push-телеметрии","Напоминания используют только систему ОС — без данных через сервер."),
 ("Без скрытых SDK","Бинарный файл содержит только то, что вы видите в этом репозитории.")],
"Архитектура","Общее ядро Rust (UniFFI) · SwiftUI iOS · Kotlin Android · SQLCipher зашифрован · ноль сети",
"⚠️ Это приложение не предоставляет медицинских консультаций."),

("IT","🇮🇹","Italiano",
"Il tuo ciclo. Il tuo telefono. Nessun server. Nessun cloud. Zero compromessi.",
[("📵","**Nessun server.** Non ne abbiamo. Nessun backend, nessun database remoto, nessun endpoint API a cui l'app si connette."),
 ("📶","**Funziona al 100% offline.** Nessuna connessione internet è mai richiesta o utilizzata. Installa una volta, usa per sempre senza rete."),
 ("🚷","**Nessun account, nessuna registrazione.** Nessuna email, nessuna password, nessun login social, nessuna verifica d'identità. Nulla."),
 ("🧩","**Nessuna dipendenza da servizi di terze parti.** Nessun Firebase, Google Analytics, Mixpanel, Sentry, Amplitude. Zero SDK esterni."),
 ("🔐","**Dati cifrati solo sul tuo telefono.** Database SQLCipher cifrato con AES-256-GCM. Chiave derivata dal tuo PIN via Argon2id. La chiave non lascia mai il dispositivo."),
 ("☁️","**Backup cloud opzionale — completamente cifrato.** iCloud/Google Drive riceve un blob cifrato opaco. Nemmeno Apple e Google possono leggerlo."),
 ("🚫","**Zero telemetria, zero analytics.** Nessun report di crash, nessuna metrica di utilizzo, nessun A/B test. Niente lascia il tuo telefono."),
 ("💥","**Cancellazione di emergenza in 3 secondi.** Tieni premuto il pulsante: database + salt + tutte le chiavi crittografiche vengono distrutte irreversibilmente."),
 ("🔓","**100% open source.** MIT/Apache-2.0. Ogni riga di codice è pubblica e verificabile da chiunque.")],
"Cosa LUNA non farà MAI",
[("Nessun server","Non ne abbiamo. Impossibile inviare i tuoi dati da qualsiasi parte."),
 ("Senza internet","L'app funziona al 100% offline. Sempre."),
 ("Senza account","Senza email, senza password, senza login."),
 ("Senza vendita di dati","Impossibile — non li riceviamo mai."),
 ("Senza pubblicità","Zero SDK pubblicitari, zero pixel di tracciamento."),
 ("Senza telemetria push","I promemoria usano solo il sistema OS — nessun dato via server."),
 ("Senza SDK nascosti","Il binario contiene solo ciò che vedi in questo repository.")],
"Architettura","Core Rust condiviso (UniFFI) · SwiftUI iOS · Kotlin Android · SQLCipher cifrato · zero rete",
"⚠️ Questa app non fornisce consulenza medica."),

("NL","🇳🇱","Nederlands",
"Jouw cyclus. Jouw telefoon. Geen server. Geen cloud. Nul compromissen.",
[("📵","**Geen server.** Wij hebben er geen. Geen backend, geen externe database, geen API-eindpunt waarmee de app verbinding maakt."),
 ("📶","**Werkt 100% offline.** Er is nooit een internetverbinding nodig of wordt gebruikt. Eenmalig installeren, altijd gebruiken zonder netwerk."),
 ("🚷","**Geen account, geen registratie.** Geen e-mail, geen wachtwoord, geen sociale login, geen identiteitsverificatie. Niets."),
 ("🧩","**Geen afhankelijkheid van diensten van derden.** Geen Firebase, Google Analytics, Mixpanel, Sentry, Amplitude. Nul externe SDK's."),
 ("🔐","**Gegevens alleen versleuteld op jouw telefoon.** SQLCipher-database versleuteld met AES-256-GCM. Sleutel afgeleid van jouw PIN via Argon2id. De sleutel verlaat het apparaat nooit."),
 ("☁️","**Optionele cloudback-up — volledig versleuteld.** iCloud/Google Drive ontvangt een ondoorzichtige versleutelde blob. Zelfs Apple en Google kunnen het niet lezen."),
 ("🚫","**Nul telemetrie, nul analytics.** Geen crashrapporten, geen gebruiksstatistieken, geen A/B-tests. Niets verlaat jouw telefoon."),
 ("💥","**Paniekvegwissen in 3 seconden.** Houd de knop ingedrukt: database + salt + alle cryptografische sleutels worden onomkeerbaar vernietigd."),
 ("🔓","**100% open source.** MIT/Apache-2.0. Elke regel code is openbaar en door iedereen te auditen.")],
"Wat LUNA NOOIT zal doen",
[("Geen server","Wij hebben er geen. Onmogelijk om jouw gegevens ergens naartoe te sturen."),
 ("Geen internet nodig","De app werkt 100% offline. Altijd."),
 ("Geen account","Geen e-mail, geen wachtwoord, geen login."),
 ("Geen dataverkoop","Onmogelijk — we ontvangen het nooit."),
 ("Geen advertenties","Nul advertentie-SDK, nul trackingpixels."),
 ("Geen push-telemetrie","Herinneringen gebruiken alleen het OS-systeem — geen gegevens via server."),
 ("Geen verborgen SDK","Het binaire bestand bevat alleen wat je in deze repository ziet.")],
"Architectuur","Gedeelde Rust-kern (UniFFI) · SwiftUI iOS · Kotlin Android · SQLCipher versleuteld · nul netwerk",
"⚠️ Deze app biedt geen medisch advies."),

("KO","🇰🇷","한국어",
"당신의 주기. 당신의 전화기. 서버 없음. 클라우드 없음. 타협 없음.",
[("📵","**서버 없음.** 우리는 서버가 없습니다. 백엔드 없음, 원격 데이터베이스 없음, 앱이 연결하는 API 엔드포인트 없음."),
 ("📶","**100% 오프라인 작동.** 인터넷 연결이 필요하거나 사용된 적이 없습니다. 한 번 설치하면 네트워크 없이 영원히 사용 가능합니다."),
 ("🚷","**계정 없음, 가입 없음.** 이메일 없음, 비밀번호 없음, 소셜 로그인 없음, 신원 확인 없음. 아무것도 없습니다."),
 ("🧩","**타사 서비스 의존성 없음.** Firebase, Google Analytics, Mixpanel, Sentry, Amplitude 없음. 외부 SDK 제로."),
 ("🔐","**데이터는 전화기에만 암호화 저장.** AES-256-GCM으로 암호화된 SQLCipher 데이터베이스. Argon2id를 통해 PIN에서 파생된 키. 키는 장치를 절대 떠나지 않습니다."),
 ("☁️","**선택적 클라우드 백업 — 완전 암호화.** iCloud/Google Drive는 불투명한 암호화된 블롭을 받습니다. Apple과 Google도 읽을 수 없습니다."),
 ("🚫","**텔레메트리 제로, 분석 제로.** 충돌 보고서 없음, 사용 메트릭 없음, A/B 테스트 없음. 전화기를 떠나는 것은 아무것도 없습니다."),
 ("💥","**3초 패닉 와이프.** 버튼을 길게 누르세요: 데이터베이스 + 솔트 + 모든 암호화 키가 되돌릴 수 없이 파괴됩니다."),
 ("🔓","**100% 오픈 소스.** MIT/Apache-2.0. 모든 코드 줄이 공개되어 있고 누구나 감사할 수 있습니다.")],
"LUNA가 절대 하지 않을 일",
[("서버 없음","우리는 없습니다. 데이터를 어디에도 보낼 수 없습니다."),
 ("인터넷 불필요","앱은 100% 오프라인으로 작동합니다. 항상."),
 ("계정 없음","이메일 없음, 비밀번호 없음, 로그인 없음."),
 ("데이터 판매 없음","불가능 — 우리는 절대 수신하지 않습니다."),
 ("광고 없음","광고 SDK 제로, 추적 픽셀 제로."),
 ("푸시 텔레메트리 없음","알림은 OS 시스템만 사용 — 서버를 통한 데이터 없음."),
 ("숨겨진 SDK 없음","바이너리에는 이 저장소에서 보는 것만 포함됩니다.")],
"아키텍처","공유 Rust 코어 (UniFFI) · SwiftUI iOS · Kotlin Android · SQLCipher 암호화 · 제로 네트워크",
"⚠️ 이 앱은 의료 조언을 제공하지 않습니다."),

("HI","🇮🇳","हिंदी",
"आपका चक्र। आपका फ़ोन। कोई सर्वर नहीं। कोई क्लाउड नहीं। शून्य समझौता।",
[("📵","**कोई सर्वर नहीं।** हमारे पास कोई नहीं है। कोई बैकएंड नहीं, कोई रिमोट डेटाबेस नहीं, कोई API एंडपॉइंट नहीं जिससे ऐप कनेक्ट हो।"),
 ("📶","**100% ऑफ़लाइन काम करता है।** इंटरनेट कनेक्शन कभी ज़रूरी नहीं होता और न ही उपयोग होता है। एक बार इंस्टॉल करें, नेटवर्क के बिना हमेशा के लिए उपयोग करें।"),
 ("🚷","**कोई खाता नहीं, कोई पंजीकरण नहीं।** कोई ईमेल नहीं, कोई पासवर्ड नहीं, कोई सोशल लॉगिन नहीं, कोई पहचान सत्यापन नहीं। कुछ भी नहीं।"),
 ("🧩","**किसी तृतीय पक्ष सेवा पर निर्भरता नहीं।** कोई Firebase, Google Analytics, Mixpanel, Sentry, Amplitude नहीं। शून्य बाहरी SDK।"),
 ("🔐","**डेटा केवल आपके फ़ोन पर एन्क्रिप्टेड।** AES-256-GCM एन्क्रिप्टेड SQLCipher डेटाबेस। Argon2id के माध्यम से PIN से व्युत्पन्न कुंजी। कुंजी कभी डिवाइस नहीं छोड़ती।"),
 ("☁️","**वैकल्पिक क्लाउड बैकअप — पूरी तरह एन्क्रिप्टेड।** iCloud/Google Drive को एक अपारदर्शी एन्क्रिप्टेड ब्लॉब मिलता है। Apple और Google भी इसे नहीं पढ़ सकते।"),
 ("🚫","**शून्य टेलीमेट्री, शून्य एनालिटिक्स।** कोई क्रैश रिपोर्ट नहीं, कोई उपयोग मेट्रिक्स नहीं, कोई A/B परीक्षण नहीं। कुछ भी आपके फ़ोन को नहीं छोड़ता।"),
 ("💥","**3 सेकंड में पैनिक वाइप।** बटन दबाए रखें: डेटाबेस + नमक + सभी क्रिप्टोग्राफ़िक कुंजियाँ अपरिवर्तनीय रूप से नष्ट हो जाती हैं।"),
 ("🔓","**100% ओपन सोर्स।** MIT/Apache-2.0। हर कोड लाइन सार्वजनिक है और किसी के द्वारा भी ऑडिट करने योग्य है।")],
"LUNA कभी क्या नहीं करेगा",
[("कोई सर्वर नहीं","हमारे पास नहीं है। आपका डेटा कहीं भेजना असंभव है।"),
 ("इंटरनेट की ज़रूरत नहीं","ऐप 100% ऑफ़लाइन काम करता है। हमेशा।"),
 ("कोई खाता नहीं","कोई ईमेल नहीं, कोई पासवर्ड नहीं, कोई लॉगिन नहीं।"),
 ("डेटा की बिक्री नहीं","असंभव — हम इसे कभी प्राप्त नहीं करते।"),
 ("कोई विज्ञापन नहीं","शून्य विज्ञापन SDK, शून्य ट्रैकिंग पिक्सेल।"),
 ("पुश टेलीमेट्री नहीं","रिमाइंडर केवल OS सिस्टम का उपयोग करते हैं — सर्वर के माध्यम से कोई डेटा नहीं।"),
 ("कोई छिपा SDK नहीं","बाइनरी में केवल वही है जो आप इस रिपॉजिटरी में देखते हैं।")],
"वास्तुकला","साझा Rust कोर (UniFFI) · SwiftUI iOS · Kotlin Android · SQLCipher एन्क्रिप्टेड · शून्य नेटवर्क",
"⚠️ यह ऐप चिकित्सा सलाह प्रदान नहीं करता है।"),

]

# For remaining 28 languages, use a compact pledge in English with localized title
LANGS_EN_PLEDGE = [
("PL","🇵🇱","Polski","Twój cykl. Twój telefon. Zero serwera. Zero chmury. Zero kompromisów.",
 "Co LUNA nigdy nie zrobi","Architektura"),
("TR","🇹🇷","Türkçe","Döngünüz. Telefonunuz. Sunucu yok. Bulut yok. Taviz yok.",
 "LUNA'nın ASLA yapmayacağı","Mimari"),
("SV","🇸🇪","Svenska","Din cykel. Din telefon. Ingen server. Inget moln. Inga kompromisser.",
 "Vad LUNA ALDRIG kommer att göra","Arkitektur"),
("DA","🇩🇰","Dansk","Din cyklus. Din telefon. Ingen server. Ingen sky. Nul kompromis.",
 "Hvad LUNA ALDRIG vil gøre","Arkitektur"),
("NO","🇳🇴","Norsk","Din syklus. Din telefon. Ingen server. Ingen sky. Null kompromiss.",
 "Hva LUNA ALDRI vil gjøre","Arkitektur"),
("FI","🇫🇮","Suomi","Syklisi. Puhelimesi. Ei palvelinta. Ei pilveä. Nolla kompromissia.",
 "Mitä LUNA EI KOSKAAN tee","Arkkitehtuuri"),
("CS","🇨🇿","Čeština","Váš cyklus. Váš telefon. Žádný server. Žádný cloud. Nulový kompromis.",
 "Co LUNA NIKDY neudělá","Architektura"),
("HU","🇭🇺","Magyar","A te ciklusod. A te telefonod. Nincs szerver. Nincs felhő. Nulla kompromisszum.",
 "Amit a LUNA SOHA nem fog csinálni","Architektúra"),
("RO","🇷🇴","Română","Ciclul tău. Telefonul tău. Niciun server. Niciun cloud. Zero compromisuri.",
 "Ce nu va face LUNA NICIODATĂ","Arhitectură"),
("EL","🇬🇷","Ελληνικά","Ο κύκλος σας. Το τηλέφωνό σας. Κανένας διακομιστής. Κανένο cloud. Μηδέν συμβιβασμοί.",
 "Τι δεν θα κάνει ΠΟΤΈ η LUNA","Αρχιτεκτονική"),
("VI","��🇳","Tiếng Việt","Chu kỳ của bạn. Điện thoại của bạn. Không máy chủ. Không đám mây. Không thỏa hiệp.",
 "Những gì LUNA sẽ KHÔNG BAO GIỜ làm","Kiến trúc"),
("TH","🇹🇭","ภาษาไทย","รอบเดือนของคุณ โทรศัพท์ของคุณ ไม่มีเซิร์ฟเวอร์ ไม่มีคลาวด์ ไม่มีการประนีประนอม",
 "สิ่งที่ LUNA จะไม่ทำ","สถาปัตยกรรม"),
("ID","🇮🇩","Bahasa Indonesia","Siklus Anda. Ponsel Anda. Tanpa server. Tanpa cloud. Nol kompromi.",
 "Yang tidak akan PERNAH dilakukan LUNA","Arsitektur"),
("MS","🇲🇾","Bahasa Melayu","Kitaran anda. Telefon anda. Tiada pelayan. Tiada awan. Sifar kompromi.",
 "Apa yang tidak akan PERNAH dilakukan LUNA","Seni bina"),
("FA","🇮🇷","فارسی","چرخه شما. تلفن شما. بدون سرور. بدون ابر. بدون مصالحه.",
 "آنچه LUNA هرگز نخواهد کرد","معماری"),
("HE","🇮🇱","עברית","המחזור שלך. הטלפון שלך. אין שרת. אין ענן. אפס פשרות.",
 "מה LUNA לעולם לא תעשה","ארכיטקטורה"),
("HR","🇭🇷","Hrvatski","Vaš ciklus. Vaš telefon. Bez poslužitelja. Bez oblaka. Nula kompromisa.",
 "Što LUNA NIKADA neće učiniti","Arhitektura"),
("BG","🇧🇬","Български","Вашият цикъл. Вашият телефон. Без сървър. Без облак. Нулев компромис.",
 "Какво LUNA НИКОГА няма да направи","Архитектура"),
("SR","🇷🇸","Српски","Ваш циклус. Ваш телефон. Без сервера. Без облака. Нула компромиса.",
 "Шта ЛУНА НИКАДА неће урадити","Архитектура"),
("SK","🇸🇰","Slovenčina","Váš cyklus. Váš telefón. Žiadny server. Žiadny cloud. Nulový kompromis.",
 "Čo LUNA NIKDY neurobí","Architektúra"),
("CA","🌐","Català","El teu cicle. El teu telèfon. Cap servidor. Cap núvol. Zero compromisos.",
 "El que LUNA MAI farà","Arquitectura"),
("EU","🌐","Euskara","Zure zikloa. Zure telefonoa. Zerbitzaririk ez. Lainorik ez. Zero konpromisorik.",
 "LUNAk INOIZ egingo ez duena","Arkitektura"),
("GL","🌐","Galego","O teu ciclo. O teu teléfono. Sen servidor. Sen nube. Cero compromisos.",
 "O que LUNA NUNCA fará","Arquitectura"),
("BN","🇧🇩","বাংলা","আপনার চক্র। আপনার ফোন। কোনো সার্ভার নেই। কোনো ক্লাউড নেই। শূন্য আপোস।",
 "LUNA কখনই যা করবে না","স্থাপত্য"),
("ML","🇮🇳","മലയാളം","നിങ്ങളുടെ ചക്രം. നിങ്ങളുടെ ഫോൺ. സെർവർ ഇല്ല. ക്ലൗഡ് ഇല്ല. ഒരു വിട്ടുവീഴ്ചയും ഇല്ല.",
 "LUNA ഒരിക്കലും ചെയ്യാത്തത്","ആർക്കിടെക്ചർ"),
("UK","🇺🇦","Українська","Ваш цикл. Ваш телефон. Жодних серверів. Жодної хмари. Нуль компромісів.",
 "Що LUNA НІКОЛИ не робитиме","Архітектура"),
]

RTL = {"AR","HE","FA"}

EN_PLEDGE_9 = [
("📵","**No server.** We do not have one. No backend, no remote database, no API endpoint the app ever calls."),
("📶","**Works 100% offline.** No internet connection is ever required or used. Install once, use forever without a network."),
("🚷","**No account, no registration.** No email, no password, no social login, no identity verification. Nothing."),
("🧩","**No third-party service dependency.** No Firebase, no Google Analytics, no Mixpanel, no Sentry, no Amplitude. Zero external SDKs."),
("🔐","**Data encrypted on your phone only.** AES-256-GCM encrypted SQLCipher database. Key derived from your PIN via Argon2id. The key never leaves the device."),
("☁️","**Optional encrypted backup.** iCloud/Google Drive receives an opaque ciphertext blob. Even Apple and Google cannot read it."),
("🚫","**Zero telemetry, zero analytics.** No crash reports, no usage metrics, no A/B tests. Nothing leaves your phone."),
("💥","**Panic wipe in 3 seconds.** Hold the button: database + salt + all cryptographic keys destroyed irreversibly."),
("🔓","**100% open source.** MIT/Apache-2.0. Every line of code is public and auditable by anyone."),
]
EN_NEVER_ROWS = [
("No server","We don't have one. Impossible to send your data anywhere."),
("No internet required","The app works 100% offline. Always."),
("No account","No email, no password, no login."),
("No data sale","Impossible — we never receive it."),
("No ads","Zero advertising SDK, zero tracking pixel."),
("No push telemetry","Reminders use OS system only — no data via any server."),
("No hidden SDK","The binary contains only what you see in this repository."),
]

def gen_full(code, flag, lang_native, tagline, pledge9, never_title, never_rows, arch_title, arch_desc, note):
    rtl = code in RTL
    dir_attr = ' dir="rtl"' if rtl else ''
    s = []
    s.append(f'<div align="center"{dir_attr}>\n\n')
    s.append(f'# LUNA — {lang_native}\n\n')
    s.append(f'**{tagline}**\n\n')
    s.append(f'[![No server](https://img.shields.io/badge/server-none-brightgreen.svg)](#)\n')
    s.append(f'[![Offline](https://img.shields.io/badge/works-100%25%20offline-brightgreen.svg)](#)\n')
    s.append(f'[![License](https://img.shields.io/badge/license-MIT%20%2F%20Apache--2.0-blue.svg)]({BACK})\n\n')
    s.append(f'</div>\n\n')
    s.append(f'[← English (full docs)]({BACK})\n\n---\n\n')

    # Privacy pledge
    privacy_title = {
        "AR":"التزام الخصوصية","HE":"מחויבות הפרטיות","FA":"تعهد حریم خصوصی",
        "JA":"プライバシーの誓約","ZH-Hans":"隐私承诺","ZH-Hant":"隱私承諾",
        "KO":"개인정보 약속","HI":"गोपनीयता प्रतिज्ञा","RU":"Обязательство конфиденциальности",
        "DE":"Datenschutzversprechen","FR":"La promesse de confidentialité",
        "ES":"Promesa de privacidad","IT":"Promessa sulla privacy","NL":"Privacybelofte",
        "PT-BR":"Compromisso de privacidade","BN":"গোপনীয়তার প্রতিশ্রুতি",
        "ML":"സ്വകാര്യതാ പ്രതിജ്ഞ",
    }.get(code, "Privacy Pledge")

    s.append(f'## {privacy_title}\n\n')
    s.append('| | |\n|---|---|\n')
    for icon, text in pledge9:
        s.append(f'| {icon} | {text} |\n')
    s.append('\n---\n\n')

    # Never do
    s.append(f'## {never_title}\n\n')
    s.append('| | |\n|---|---|\n')
    for what, why in never_rows:
        s.append(f'| **{what}** | {why} |\n')
    s.append('\n')
    # Technical enforcement (English — it's a code block)
    s.append('```\n')
    s.append('iOS:     ATS enforced — no arbitrary network loads\n')
    s.append('Android: networkSecurityConfig blocks ALL outbound connections\n')
    s.append('Rust:    Cargo.toml has zero networking dependencies\n')
    s.append('```\n\n---\n\n')

    # Screenshots
    s.append('## Screenshots\n\n')
    s.append('| Home | Log | Calendar | Insights | Security |\n')
    s.append('|------|-----|----------|----------|---------|\n')
    lang_code_lower = code.lower().split('-')[0] if '-' not in code else code.lower()
    # Use EN screenshots for langs without dedicated screenshots
    sc = lang_code_lower if lang_code_lower in {'en','fr','de','es','ja'} else 'en'
    s.append(f'| ![](../../docs/screenshots/01_home_{sc}.png) | ![](../../docs/screenshots/02_log_{sc}.png) | ![](../../docs/screenshots/03_calendar_{sc}.png) | ![](../../docs/screenshots/04_insights_en.png) | ![](../../docs/screenshots/05_security_en.png) |\n\n')
    s.append('---\n\n')

    # Architecture
    s.append(f'## {arch_title}\n\n```\n{arch_desc}\n```\n\n---\n\n')
    s.append(f'## License\n\nMIT / Apache-2.0 — [LICENSE]({BACK})\n\n')
    s.append(f'> {note}\n')
    return ''.join(s)

def gen_compact(code, flag, lang_native, tagline, never_title, arch_title):
    """For langs without full translation — uses EN pledge + translated title/tagline."""
    rtl = code in RTL
    dir_attr = ' dir="rtl"' if rtl else ''
    arch_map = {
        "Architektura":"Shared Rust Core (UniFFI) · SwiftUI iOS · Kotlin Android · SQLCipher encrypted · zero network",
        "Architektúra":"Shared Rust Core (UniFFI) · SwiftUI iOS · Kotlin Android · SQLCipher encrypted · zero network",
        "Архитектура":"Общее ядро Rust (UniFFI) · SwiftUI iOS · Kotlin Android · SQLCipher зашифрован · ноль сети",
        "Архітектура":"Спільне ядро Rust (UniFFI) · SwiftUI iOS · Kotlin Android · SQLCipher зашифровано · нуль мережі",
        "Architektúra":"Zdieľané Rust jadro (UniFFI) · SwiftUI iOS · Kotlin Android · SQLCipher šifrovaný · nula sieť",
        "Arquitectura":"Núcleo Rust compartido (UniFFI) · SwiftUI iOS · Kotlin Android · SQLCipher cifrado · cero red",
        "Arkitektur":"Delt Rust-kerne (UniFFI) · SwiftUI iOS · Kotlin Android · SQLCipher krypteret · nul netværk",
        "Arkkitehtuuri":"Jaettu Rust-ydin (UniFFI) · SwiftUI iOS · Kotlin Android · SQLCipher salattu · nolla verkko",
        "Kiến trúc":"Nhân Rust chia sẻ (UniFFI) · SwiftUI iOS · Kotlin Android · SQLCipher mã hóa · không mạng",
        "สถาปัตยกรรม":"Rust core ที่ใช้ร่วมกัน (UniFFI) · SwiftUI iOS · Kotlin Android · SQLCipher เข้ารหัส · ไม่มีเครือข่าย",
        "Arsitektur":"Inti Rust bersama (UniFFI) · SwiftUI iOS · Kotlin Android · SQLCipher terenkripsi · nol jaringan",
        "Seni bina":"Teras Rust dikongsi (UniFFI) · SwiftUI iOS · Kotlin Android · SQLCipher disulitkan · sifar rangkaian",
        "معماری":"هسته Rust مشترک (UniFFI) · SwiftUI iOS · Kotlin Android · SQLCipher رمزنگاری شده · صفر شبکه",
        "ארכיטקטורה":"ליבת Rust משותפת (UniFFI) · SwiftUI iOS · Kotlin Android · SQLCipher מוצפן · אפס רשת",
        "Arhitektura":"Zajednička Rust jezgra (UniFFI) · SwiftUI iOS · Kotlin Android · SQLCipher šifrirano · nula mreža",
        "Архитектура":"Заједничка Rust језгра (UniFFI) · SwiftUI iOS · Kotlin Android · SQLCipher шифровано · нула мрежа",
        "Αρχιτεκτονική":"Κοινός πυρήνας Rust (UniFFI) · SwiftUI iOS · Kotlin Android · SQLCipher κρυπτογραφημένο · μηδέν δίκτυο",
        "Arquitectura":"Nucli Rust compartit (UniFFI) · SwiftUI iOS · Kotlin Android · SQLCipher xifrat · zero xarxa",
        "Arkitektura":"Partekatutako Rust nukleoa (UniFFI) · SwiftUI iOS · Kotlin Android · SQLCipher enkriptatua · zero sare",
        "স্থাপত্য":"ভাগ করা Rust কোর (UniFFI) · SwiftUI iOS · Kotlin Android · SQLCipher এনক্রিপ্টেড · শূন্য নেটওয়ার্ক",
        "ആർക്കിടെക്ചർ":"പങ്കിട്ട Rust കോർ (UniFFI) · SwiftUI iOS · Kotlin Android · SQLCipher എൻക്രിപ്റ്റ് · ശൂന്യ ശൃംഖല",
    }
    arch_desc = arch_map.get(arch_title, "Shared Rust Core (UniFFI) · SwiftUI iOS · Kotlin Android · SQLCipher encrypted · zero network")
    note = "⚠️ This app does not provide medical advice."

    s = []
    s.append(f'<div align="center"{dir_attr}>\n\n')
    s.append(f'# LUNA — {lang_native}\n\n')
    s.append(f'**{tagline}**\n\n')
    s.append(f'[![No server](https://img.shields.io/badge/server-none-brightgreen.svg)](#)\n')
    s.append(f'[![Offline](https://img.shields.io/badge/works-100%25%20offline-brightgreen.svg)](#)\n')
    s.append(f'[![License](https://img.shields.io/badge/license-MIT%20%2F%20Apache--2.0-blue.svg)]({BACK})\n\n')
    s.append(f'</div>\n\n')
    s.append(f'[← English (full docs)]({BACK})\n\n---\n\n')
    s.append('## Privacy Pledge\n\n')
    s.append('| | |\n|---|---|\n')
    for icon, text in EN_PLEDGE_9:
        s.append(f'| {icon} | {text} |\n')
    s.append(f'\n---\n\n## {never_title}\n\n')
    s.append('| | |\n|---|---|\n')
    for what, why in EN_NEVER_ROWS:
        s.append(f'| **{what}** | {why} |\n')
    s.append('\n```\n')
    s.append('iOS:     ATS enforced — no arbitrary network loads\n')
    s.append('Android: networkSecurityConfig blocks ALL outbound connections\n')
    s.append('Rust:    Cargo.toml has zero networking dependencies\n')
    s.append('```\n\n---\n\n')
    s.append('## Screenshots\n\n')
    s.append('| Home | Log | Calendar | Insights | Security |\n')
    s.append('|------|-----|----------|----------|---------|\n')
    s.append('| ![](../../docs/screenshots/01_home_en.png) | ![](../../docs/screenshots/02_log_en.png) | ![](../../docs/screenshots/03_calendar_en.png) | ![](../../docs/screenshots/04_insights_en.png) | ![](../../docs/screenshots/05_security_en.png) |\n\n')
    s.append(f'---\n\n## {arch_title}\n\n```\n{arch_desc}\n```\n\n---\n\n')
    s.append(f'## License\n\nMIT / Apache-2.0 — [LICENSE]({BACK})\n\n')
    s.append(f'> {note}\n')
    return ''.join(s)

count = 0
for entry in LANGS:
    code = entry[0]
    content = gen_full(*entry)
    out = os.path.join(OUT_DIR, f"README_{code}.md")
    with open(out, 'w', encoding='utf-8') as f:
        f.write(content)
    count += 1
    print(f"  {code}")

for entry in LANGS_EN_PLEDGE:
    code, flag, lang_native, tagline, never_title, arch_title = entry
    content = gen_compact(code, flag, lang_native, tagline, never_title, arch_title)
    out = os.path.join(OUT_DIR, f"README_{code}.md")
    with open(out, 'w', encoding='utf-8') as f:
        f.write(content)
    count += 1
    print(f"  {code}")

print(f"\nGenerated {count} README translations in {OUT_DIR}/")
