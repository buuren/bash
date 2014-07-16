Интересные приемы программирования на Bash 
Эти приемы были описаны во внутреннем проекте компании Google «Testing on the Toilet» (Тестируем в туалете — распространение листовок в туалетах, что бы напоминать разработчикам о тестах).
В данной статье они были пересмотрены и дополнены.


Безопасность

Я начинаю каждый скрипт со следующих строк
#!/bin/bash
set -o nounset
set -o errexit

Это защищает от двух частых ошибок
1) Попыток использовать не объявленные переменные
2) Игнорирование аварийного завершения команд
Если команда может завершиться аварийно, и нас это устраивает, можно использовать следующий код:
if ! <possible failing command> ; then
    echo "failure ignored"
fi

Нужно помнить что некоторые команды не возвращают код аварийного завершения например “mkdir -p” и “rm -f”.
Так же есть сложности с вызовом цепочек подпрограмм (command1 | command 2 | command3) из скрипта, для обхода этого ограничения можно использовать следующую конструкцию: 
(./failing_command && echo A)

В этом случае оператор '&&' не позволит выполниться следующей команде, подробнее — 'http://fvue.nl/wiki/Bash:_Error_handling'

Функции

Bash позволяет использовать функции как обычные команды, это очень сильно повышает читаемость вашего кода:
Пример 1: 
ExtractBashComments() {
    egrep "^#"
} 
cat myscript.sh | ExtractBashComments | wc 

comments=$(ExtractBashComments < myscript.sh)

Пример 2:
SumLines() {  # iterating over stdin - similar to awk       
    local sum=0
    local line=””
    while read line ; do
        sum=$((${sum} + ${line}))
    done
    echo ${sum}
} 
SumLines < data_one_number_per_line.txt 

Пример 3:
log() {  # classic logger 
   local prefix="[$(date +%Y/%m/%d\ %H:%M:%S)]: "
   echo "${prefix} $@" >&2
} 
log "INFO" "a message"

Попробуйте перенести весь ваш код в функции оставив только глобальные переменные/константы и вызов функции «main» в которой будет вся высокоуровневая логика.

Объявление переменных

Bash позволяет объявлять переменные нескольких типов, самые важные:
local (Для переменных используемых только внутри функций)
readonly (Переменные попытка переназначения которых вызывает ошибку)
## Если DEFAULT_VAL уже объявлена, то использовать ее значение, иначе использовать '-7'
readonly DEFAULT_VAL=${DEFAULT_VAL:-7} 

myfunc() {
   # Использование локальной переменной со значением глобальной
   local some_var=${DEFAULT_VAL}
   ...
}

Есть возможность сделать переменную типа readonly из уже объявленной:
x=5
x=6
readonly x
x=7   # failure

Стремитесь к тому что бы все ваши переменные были либо local, либо readonly, это улучшит читаемость и снизит количество ошибок.

Используйте $() вместо обратных кавычек ``

Обратные кавычки плохо читаются и в некоторых шрифтах легко могут быть перепутаны с одинарными кавычками.
Конструкция $() так же позволяет использовать вложенные вызовы без головной боли с экранированием:
# обе команды выводят: A-B-C-D
echo "A-`echo B-\`echo C-\\\`echo D\\\`\``"
echo "A-$(echo B-$(echo C-$(echo D)))"


Используйте двойные квадратные скобки [[]] вместо одинарных []

Двойные квадратные скобки позволяют избежать непреднамеренного использования путей вместо переменных:
 $ [ a < b ]
 -bash: b: No such file or directory
 $ [[ a < b ]]

В некоторых случаях упрощают синтаксис:
[ "${name}" \> "a" -o ${name} \< "m" ]

[[ "${name}" > "a" && "${name}" < "m"  ]]

А так же предоставляют дополнительную функциональность:

Новые операторы:
|| Логическое ИЛИ (logical or) — только с двойными скобками.
&& Логическое И (logical and) — только с двойными скобками.
< Сравнение строковых переменных (string comparison) — с двойными скобками экранирование не нужно.
== Сравнение строковых переменных с подстановкой (string matching with globbing) — только с двойными скобками.
=~ Сравнение строковых переменных используя регулярные выражения (string matching with regular expressions) — только с двойными скобками.


Дополненные/измененные операторы:
-lt Цифровое сравнение (numerical comparison)
-n Строковая переменная не пуста (string is non-empty)
-z Строковая переменная пуста (string is empty)
-eq Цифровое равенство (numerical equality)
-ne Цифровое не равенство (numerical inequality)


Примеры:
t="abc123"
[[ "$t" == abc* ]]         # true (globbing)
[[ "$t" == "abc*" ]]       # false (literal matching)
[[ "$t" =~ [abc]+[123]+ ]] # true (regular expression)
[[ "$t" =~ "abc*" ]]       # false (literal matching)

Начиная с версии bash 3.2 регулярные выражения или выражения с подстановкой не должны заключаться в кавычки, если ваше выражение содержит пробелы, вы можете поместить его в пеерменную:
r="a b+"
[[ "a bbb" =~ $r ]]        # true

Сравнене строковых переменных с подстановкой так же доступно в операторе case:
case $t in
abc*)  <action> ;;
esac


Работа со строковыми переменными:

В bash встроено несколько (недооцененных) возможностей работы со строковыми переменными:
Базовые:
f="path1/path2/file.ext"  
len="${#f}" # = 20 (длина строковой переменной) 
# выделение участка из переменной: ${<переменная>:<начало_участка>} или ${<переменная>:<начало_участка>:<размер_участка>}
slice1="${f:6}" # = "path2/file.ext"
slice2="${f:6:5}" # = "path2"
slice3="${f: -8}" # = "file.ext" (обратите внимание на пробел перед знаком '-')
pos=6
len=5
slice4="${f:${pos}:${len}}" # = "path2"

Замена с подстановкой:
f="path1/path2/file.ext"  
single_subst="${f/path?/x}"   # = "x/path2/file.ext" (змена первого совпадения)
global_subst="${f//path?/x}"  # = "x/x/file.ext" (замена всех совпадений)

Разделение переменных:
f="path1/path2/file.ext" 
readonly DIR_SEP="/"
array=(${f//${DIR_SEP}/ })
second_dir="${arrray[1]}"     # = path2

Удаление с подстановкой:
# Удаление с начала строки, до первого совпадения
f="path1/path2/file.ext" 
extension="${f#*.}"  # = "ext" 

# Удаление с начала строки, до последнего совпадения
f="path1/path2/file.ext" 
filename="${f##*/}"  # = "file.ext" 

# Удаление с конца строки, до первого совпадения
f="path1/path2/file.ext" 
dirname="${f%/*}"    # = "path1/path2" 

# Удаление с конца строки, до последнего совпадения
f="path1/path2/file.ext" 
root="${f%%/*}"      # = "path1"


Избавляемся от временных файлов

Некоторые команды ожидают на вход имя файла, с ними нам поможет оператор '<()', он принимает на вход команду и преобразует в нечто что можно использовать как имя файла:
# скачать два URLa и передать их в diff
diff <(wget -O - url1) <(wget -O - url2)

Использование маркера для передачи многострочных переменных:
# MARKER — любое слово.
command  << MARKER
...
${var}
$(cmd)
...
MARKER

Если нужно избежать подстановки, то маркер можно взять в кавычки:
# конструкция вернет '$var' а не значение переменной 
var="text"
cat << 'MARKER'
...
$var
...
MARKER


Встроенные переменные

$0 Имя скрипта (name of the script)
$1 $2… $n Параметры переданные скрипту/фнукции (positional parameters to script/function)
$$ PID скрипта (PID of the script)
$! PID последней команды выполненной в фоне(PID of the last command executed (and run in the background))
$? Статус возвращенный последней командой (exit status of the last command (${PIPESTATUS} for pipelined commands))
$# Количество параметров переданных скрипту/функции (number of parameters to script/function)
$@ Все параметры переданные скрипту/функции, представленные в виде слов (sees arguments as separate word)
$* Все параметры переданные скрипту/функции, представленные в виде одного слова (sees arguments as single word)
Как правило:
$* Редко является полезной
$@ Корректно обрабатывает пустые параметры и параметры с пробелами
$@ При использовании обычно заключается в двойные кавычки — "$@"

Пример:
for i in "$@"; do echo '$@ param:' $i; done
for i in "$*"; do echo '$! param:' $i; done

вывод:
bash ./parameters.sh arg1 arg2
$@ param: arg1
$@ param: arg2
$! param: arg1 arg2


Отладка

Проверка синтаксиса (экономит время если скрипт выполняется дольше 15 секунд): 
bash -n myscript.sh

Трассировка:
bash -v myscripts.sh

Трассировка с раскрытием сложных команд:
bash -x myscript.sh

Параметры -v и -x можно задать в коде, это может быть полезно если ваш скрипт работает на одной машине а журналирование ведется на другой:
set -o verbose
set -o xtrace

Признаки того, что вы не должны использовать shell скрипты:

Ваш скрипт содержит более нескольких сотен строк.
Вам нужны структуры данных сложнее обычных массивов.
Вас задолбало заниматься непотребствами с кавычками и экранированием.
Вам необходимо обрабатывать/изменять много строковых переменных.
У вас нет необходимости вызывать сторонние програмы и нет необходимости в пайпах.
Для вас важна скорость/производительность.

Если ваш проект соответствует пунктам из этого списка, рассмотрите для него языки языки Python или Ruby.
Ссылки: 
Advanced Bash-Scripting Guide: tldp.org/LDP/abs/html/
Bash Reference Manual: www.gnu.org/software/bash/manual/bashref.html
Оригинал статьи: robertmuth.blogspot.ru/2012/08/better-bash-scripting-in-15-minutes.html