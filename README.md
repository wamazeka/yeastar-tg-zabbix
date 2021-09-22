# yeastar-zabbix
Template for monitoring SIM's in Yeastar TG-series (TG200, TG400, TG800, TG1600) gateways and balance checking on RU operators

Main script and ideas from [@AcidVenom](https://gist.github.com/andrewmagaz)
More about in [article](https://habr.com/ru/post/454702/) on Habr

Make some comments in script and little remarks.
For XML template add balance check & graphs for RU GSM operators.  

## Что отслеживает:
- ICMP пинг и отклик через присоединенный шаблон по умолчанию,
- Статус сим-карты в шлюзе (зарегистрирована, ошибка),
- Настройки регистрации в сети (смс-центр, оператор, роуминг, IMSI),
- Качество связи (уровень сигнала)
- Баланс средств на сим-карте (только для 4 российских операторов и второй ревизии железа)

## Как работает:
После создания узла сети в Zabbix начинается мониторинг оборудования через ICMP пинг. 

Далее, вступает в дело Discovery правило, по IP адресу и данным к API через внешний скрипт `yeastar-discovery.sh` происходит обращение к AMI Asterisk с помощью netcat, которая просто печатает запрос в порт. Возвращается JSON со списком портов. 
<details>
  <summary>Пример discovery ответа</summary>
  
  ```javascript
{
  "data": [
    {
      "{#ID}": "2",
      "{#NUM}": "1",
      "{#POWER}": "Power on",
      "{#STATUS}": "Up"
    },
    {
      "{#ID}": "3",
      "{#NUM}": "2",
      "{#POWER}": "Undetected SIM Card",
      "{#STATUS}": "Up"
    }
  ]
}
  
  ```
  
ID отличается от NUM т.к. внутренняя нумерация в Asterisk другая
</details>

Фильтр отбрасывает выключенные порты или где не обнаружена сим-карта. Итого, через LLD создаются элементы данных только для активных сим-карт. Периодически, как и любое LLD правило запускается вновь для обнаружения новых сим-карт в шлюзе.

В исходном шаблоне был лишь один активный элемент данных и зависимые от него, которые парсили нужные куски из текста (под спойлером). Я же добавил еще один активный элемент для проверки баланса на счете сим-карты.

<details>
<summary>Причины:</summary>

- Проверка состояния портов производится очень часто, оператор может забанить, если каждые 5 минут или чаще отправлять USSD запросы - если создавать зависимый элемент данных или вставлять в существующий,
- не получилось создать элемент данных (Скрипт или HTTP агент), который в параметрах использует полученный скриптом данные,
- не хотелось создавать отдельный скрипт для этого.

</details>

<details>
  <summary>Пример ответа по конкретному порту</summary>
  
```
Asterisk Call Manager/1.1
Response: Success
Message: Authentication accepted

Response: Follows
Privilege: SMSCommand
D-channel: 2
Status: Power on, Provisioned, Up, Active,Standard
Type: CPE
Manufacturer: SIMCOM_Ltd
Model Name: SIMCOM_SIM800
Model IMEI: 894005028759112
Model CBAND:  EGSM_MODE,ALL_BAND
Revision: 1308B08SIM800M32
Network Name: Bee Line GSM
Network Status: Registered (Home network)
Signal Quality (0,31): 13
SIM IMSI: 251225532128772
SIM SMS Center Number: +79037011111
Send SMS Center Number: Undefined
Last event: USSD received
State: READY
Last send AT: AT+CREG?\r\n--END COMMAND--

Response: Goodbye
Message: Thanks for all the fish.
```
</details>

Из этого полотна зависимые элементы данных и дергают свои кусочки. Скрипт для проверки баланса использует тот же самый запрос к внешнему скрипту по отдельному графику, выдирает из ответа номер СМС-центра, по которому можно однозначно определить оператора связи сим-карты и через JS код выбирает USSD запрос для проверки баланса на сим-карте. Можно добавлять свои соответствия!

По данным строятся графики, установлены триггеры на падение баланса, в т.ч. на подозрительно большие списания, для проверки наличия ненужных платных услуг от оператора.

## Using
1. Add `yeastar-discovery.sh` in  `/usr/lib/zabbix/externalscripts/` 
2. Import `yeastar-zabbix-template.xml` in Zabbix
3. Add template to host
4. Add macros `{$TGAPI.PASS}` and `{$TGAPI.USER}` to host
5. For balance checking add `{$TGAPI.IP}` to host*


*Including macros in macros not work for me in 5.4
