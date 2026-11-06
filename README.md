# Walleter

Скидочные карты в **Passbook на iOS 6** (джейлбрейк).
Добавляете карту магазина — Walleter собирает `.pkpass` прямо на телефоне и открывает
стандартный экран «Добавить в Passbook». Подписывать пасс сертификатом Apple не нужно:
проверку подписи отключает твик [SigPass](https://github.com/bag-xml/SigPass) от bag.xml.

## Возможности

- Список карт: добавить, изменить, удалить (свайпом или кнопкой «Изменить»).
- Поля: магазин, номер, владелец, заметка, цвет карты (13 цветов).
- Штрихкоды:
  - **EAN-13** и **Code 128** — Passbook в iOS 6 их не поддерживает, поэтому Walleter
    рисует штрихкод картинкой (strip) на лицевой стороне карты. Для EAN-13 проверяется
    и при необходимости дописывается контрольная цифра.
  - **QR, PDF417, Aztec** — нативные штрихкоды Passbook.
  - Без штрихкода — только номер.
- Карта в Passbook: название магазина, номер, владелец, заметки на обороте, иконка
  с первой буквой магазина в цвете карты. Повторное добавление обновляет ту же карту.

## Установка через Cydia

Workflow `.github/workflows/build.yml` собирает два пакета и публикует APT-репозиторий
на GitHub Pages:

| Пакет | Что это |
|---|---|
| `com.theanazerka.walleter` | приложение (зависит от SigPass) |
| `bag.xml.sigpass` | SigPass, пересобранный из исходников для iOS 6 / armv7 |

Один раз включите Pages: **Settings → Pages → Build and deployment → Source: GitHub Actions**.
После пуша в основную ветку репозиторий будет доступен по адресу

```
https://theanazerka.github.io/walleter/
```

В Cydia: **Sources → Edit → Add** → этот адрес → установить **Walleter**
(SigPass подтянется сам) → respring.

> **Про HTTPS на iOS 6.** GitHub Pages работает только по HTTPS с современными
> сертификатами, а старый Cydia на iOS 6 иногда не может с ними соединиться
> (ошибка при обновлении источника). Если так случилось:
> - скачайте `.deb` из артефакта `debs` в Actions (или из релиза, если запушен тег `v*`)
>   и установите через iFile / Filza / `dpkg -i`, затем `uicache`;
> - либо выложите содержимое артефакта `cydia-repo` на любой HTTP-хостинг — это
>   готовый статический репозиторий.

## Сборка

Нужен [Theos](https://theos.dev) с iOS-тулчейном и SDK (в CI — iPhoneOS 9.3 SDK,
deployment target 6.0, `armv7`):

```sh
make package FINALPACKAGE=1
```

Проверено синтаксической проверкой clang по заголовкам iOS SDK; полная сборка
идёт в GitHub Actions. На устройстве я приложение не запускал.

Сборка репозитория из готовых `.deb`:

```sh
scripts/build_repo.sh <папка с .deb> <выходная папка>
```

Иконки и launch-картинки генерирует `scripts/make_images.py` (нужен Pillow).

## Как это устроено

```
Sources/
  WLCardListViewController   список карт
  WLCardEditViewController   редактирование + «Добавить в Passbook»
  WLPassBuilder              pass.json, иконки, strip, manifest.json → .pkpass
  WLBarcodeRenderer          EAN-13 и Code 128 (наборы B/C) в картинку
  WLZipWriter                минимальный ZIP (STORE) для .pkpass
  WLCardStore                хранение (~/Library/Application Support/Walleter)
```

`.pkpass` содержит `manifest.json` с SHA-1 файлов, но без `signature` — его
пропускает только Passbook с установленным SigPass. Без твика Walleter покажет ошибку.

## Лицензия

GPL-3.0, как и SigPass.
