#!/bin/bash

echo "Перед продолжением вам нужно настроить некоторые параметры вручную:"
echo "  - Язык ввода: " 
echo -e "    - setxkbmap (ru|en|tr) для Ctrl + (1,2,3) \n"

echo "  - Смена громкости (если не работают сочетания клавиш):"
echo "    - Увеличение: pactl -- set-sink-volume 0 +10%"
echo -e "    - Уменьшение: pactl -- set-sink-volume 0 -10% \n"

echo -e "  - Настройка приложений для Super + (1,2,3)\n"

echo -e "  - Скачать и восстановить конфигурацию xfce panel с телеграма \n"

echo "  - Настроить внешний вид терминала: "
echo "    - Задний фон: #101010 transparent"
echo "    - Scroll back: 10000"
echo "    - Cursor: blink I-beam"
echo "    - Размер: 76 cols 19 rows"
echo -e "    - Шрифт: Monospace Regular 11\n"

echo "  - Настроить внешний вид рабочей среды (темы есть в папке): "
echo "    - Общая тема и курсор будут установленны автоматически. "
echo "      После скрипта завершения их просто нужно будет просто их выбрать. "
echo "    - Курсор: Oreo Purple"
echo "    - Иконки: Tela black dark"
echo "    - Тема: Graphite Purple Dark"


echo "  - Настроить регион и формат часов:"
echo "    - Формат: %a %_d  %b - %Y.%m.%d - %R "
echo -e "    - Регион: timedatectl set-timezone Europe/Moscow\n"

echo "  - Подключить Github к PC:"
echo "    - Сгенерируйте ключ: ssh-keygen"
echo -e "    - Скопируйте ключ в Github: cat ~/.ssh/id_rsa.pub \n"


# Запрос пароля sudo
echo "Когда будете готовы введите пароль для sudo:"
read -s password

script_path=$(dirname "$0")


clear

# Скачивание и установка темы и пакетов для нее
echo -e "Загружает тему рабочего окружения\n"
echo $password | sudo -S dnf install -y sassc
wait

# TODO: Добавь возможность пропустить
cd /tmp && git clone https://github.com/vinceliuice/Graphite-gtk-theme.git Graphite && cd Graphite && /bin/bash ./install.sh -c dark -t purple  && cd /tmp && rm -rf Graphite
wait

# Установка темы для курсора
echo $password | sudo -S cp -r $script_path/src/OreoPurple /usr/share/icons

# Установка фона для экрана login
echo $password | sudo -S mv /usr/share/backgrounds/default.png /usr/share/backgrounds/default.old.png
echo $password | sudo -S cp $script_path/src/bg.png /usr/share/backgrounds/default.png


# Создаем vsprojects
# TODO: Если есть продолжить оттуда откуда возможно
echo -e "\n\nСоздаем папку проектов\n"
cd ~/Desktop && mkdir vscode_projects
cd vscode_projects && 
git clone git@github.com:miron-khoruzhenko/practice-python.git Python && wait
git clone git@github.com:miron-khoruzhenko/web-folder-backup.git Web && wait
git clone git@github.com:miron-khoruzhenko/my-notes.git Notes && wait
git clone git@github.com:miron-khoruzhenko/practice-c-cpp.git C-Cpp && wait

# Загрузка субмодулей
echo -e "\n\nЗагружаем субмодули\n"
cd Python && git submodule update --init --recursive && wait && cd .. &&
cd Web && git submodule update --init --recursive && wait && cd .. &&
cd Notes && git submodule update --init --recursive && wait && cd .. &&
cd C-Cpp && git submodule update --init --recursive && wait && cd ..

# DOC: На чем я остановился: 
# DOC: - установка темы для login screen
# DOC: nano /etc/lightdm/lightdm-gtk-greeter.conf
# DOC: Напиши README
