# Failure semantics для `@BeforeSuite` и `@AfterSuite`

Этот воспроизводимый эксперимент проверяет, что происходит при ошибках в
`@BeforeSuite`, тесте и `@AfterSuite`, а также при ошибке `@BeforeClass` в JUnit 4.
Он отделён от Workshop-проектов, чтобы
намеренно падающие сценарии не влияли на их обычный запуск.

> **Важно:** 10 из 11 сценариев намеренно завершают Maven с ошибкой.
> Это ожидаемая часть примеров. Общий скрипт `verify.ps1` завершается успешно,
> только когда все 11 сценариев соответствуют ожиданиям, включая ожидаемые ошибки.

<a id="contents"></a>

## Содержание

- [Контекст эксперимента](#experiment-context)
- [Требования и общая проверка](#verification)
- [JUnit 6.1.3](#junit-6)
- [JUnit 5.14.4](#junit-5)
- [JUnit 4.13.2](#junit-4)
- [TestNG 7.12.0](#testng)
- [Граница вывода](#scope)
- [Повторная проверка 26 октября 2026 года](#verification-2026-10-26)
- [Лицензия](#license)

<a id="experiment-context"></a>

## Контекст эксперимента

Эксперимент подготовлен для статьи «BeforeSuite и AfterSuite в JUnit 5/6:
догнал ли JUnit TestNG». Статья готовится к публикации; публичная ссылка будет
добавлена после выхода материала.
При сравнении жизненных циклов возник практический вопрос: если подготовка
окружения выбросит исключение, начнут ли выполняться тесты и будет ли вызван
завершающий хук, отвечающий за освобождение ресурсов?

Для ответа используются отдельные Maven-проекты JUnit 6, JUnit 5, JUnit 4 и
TestNG. JUnit 6 и 5 проверяются раздельно; в TestNG сравниваются обычный
`@AfterSuite` и `@AfterSuite(alwaysRun = true)`; в JUnit 4 – `@BeforeClass` /
`@AfterClass` обычного класса и класса набора. Дополнительные сценарии JUnit 6 и
TestNG показывают ошибки в самом тесте и в завершающем хуке.

Примеры намеренно минимальны: вместо внешнего сервера или базы данных они выводят
события `[EVENT]`. Это позволяет отделить факт вызова хука от корректности очистки
реального, в том числе частично созданного ресурса. Вызов завершающего хука сам по
себе ещё не доказывает, что все ресурсы освобождены.

Этот README хранит назначение эксперимента, команды воспроизведения и ожидаемые
результаты. Наблюдения относятся к указанным версиям и способу запуска;
при обновлении зависимостей соответствующие сценарии нужно проверять заново.
Эксперимент не изменяет Workshop-проекты.

В проекте [`junit-4.13.2/`](#junit-4) также сохранена проверка
`@ClassRule(order = ...)`. Она запускается отдельной командой и должна завершаться
успешно. Исходники проверки порядка и обработки ошибок используют один `pom.xml`.

В каталоге четыре самостоятельных Maven-проекта, без общего агрегирующего `pom.xml`:

| Проект                                    | Что содержит                                                                                  |
|-------------------------------------------|-----------------------------------------------------------------------------------------------|
| [`junit-6.1.3/`](junit-6.1.3/pom.xml)     | Три сценария: ошибка подготовки набора, теста и завершающего хука                             |
| [`junit-5.14.4/`](junit-5.14.4/pom.xml)   | Один сценарий: ошибка подготовки набора                                                       |
| [`junit-4.13.2/`](junit-4.13.2/pom.xml)   | Два сценария ошибки подготовки и одна проверка порядка Rules                                  |
| [`testng-7.12.0/`](testng-7.12.0/pom.xml) | Четыре сценария: ошибка подготовки с `alwaysRun` и без него, ошибка теста и завершающего хука |

<a id="verification"></a>

## Требования и общая проверка

Для примеров нужны JDK 17 или новее (в `pom.xml` задан `release=17`) и Maven 3.9.x.
Для общего скрипта нужен PowerShell 7.2 или новее (`pwsh`); отдельные команды Maven
можно выполнять без него. `java` и `mvn` должны быть доступны в `PATH`, а Maven
должен использовать нужный JDK. При первом запуске нужен доступ к Maven Central
либо настроенному зеркалу для скачивания зависимостей и плагинов.

Проверенная среда и версии зависимостей:

- JDK 21.0.10;
- Maven 3.9.12;
- Maven Surefire 3.6.0;
- JUnit 6.1.3;
- JUnit 5.14.4 / JUnit Platform 1.14.4;
- JUnit 4.13.2;
- TestNG 7.12.0.

Проверить локальную среду и запустить все сценарии из корня этого проекта:

```powershell
java -version
mvn -version
pwsh -NoProfile -File ./verify.ps1
```

[`verify.ps1`](verify.ps1) последовательно запускает 11 сценариев и проверяет:

- точный код завершения Maven: 1 для намеренной ошибки, 0 для `ClassRuleOrderTest`;
- точную последовательность `[EVENT]` / `[EVENTS]`, включая отсутствие лишнего запуска теста;
- наличие XML-отчётов Surefire и записей о тестах;
- ровно одну ожидаемую ошибку с заданными типом и сообщением для ошибочного сценария
  либо отсутствие ошибок для успешного.

Ошибка компиляции, скачивания зависимостей, отсутствие отчётов, неожиданная ошибка
или расхождение событий приводят к неуспешной проверке. Итоговый код скрипта:
`0` – все ожидания выполнены; `1` – есть расхождение или ошибка самого запуска.

Каждый запуск скрипта получает новый каталог `target/verification/<run-id>/`.
В нём сохраняются `summary.json`, а для каждого проекта и сценария – `maven.log`
и XML-отчёты в `reports/`. Старые отчёты не используются, файлы предыдущих запусков
не удаляются. Скрипт вычисляет пути относительно собственного расположения.

Самопроверка логики скрипта (без запуска Maven):

```powershell
pwsh -NoProfile -File ./tests/verify-script.tests.ps1
```

Эти проверки используют искусственные отчёты и проверяют, что скрипт отличает
ожидаемую ошибку от неожиданного успеха, неверной последовательности событий,
другого исключения, дополнительной ошибки и отсутствующего или повреждённого отчёта.

Для каждого блока команд сначала вернитесь в каталог `failure-semantics-experiment/`:
команда `cd` в начале блока отсчитывается от него. Запускайте сценарии отдельно,
передавая имя класса через `-Dscenario=...`; обычный `mvn test` без выбора сценария
не является командой запуска всех примеров.

Сценарии ошибок должны завершаться ненулевым кодом: ошибка является частью
сценария. Последовательность событий видна по строкам с префиксом `[EVENT]`.
Исключение – успешная проверка `ClassRuleOrderTest`, которая печатает `[EVENTS]`.

<a id="junit-6"></a>

## JUnit 6.1.3

Проект использует Jupiter и Suite API/Engine версии 6.1.3. Каждый класс набора
выбирает свой вложенный `SelectedCase` через `@SelectClasses`:

- [`BeforeFailsSuite`](junit-6.1.3/src/test/java/com/example/junit6/BeforeFailsSuite.java) –
  `@BeforeSuite` бросает исключение; тест не выполняется, `@AfterSuite` вызывается.
- [`TestFailsSuite`](junit-6.1.3/src/test/java/com/example/junit6/TestFailsSuite.java) –
  подготовка успешна, тест вызывает `fail(...)`, после него выполняется `@AfterSuite`.
- [`AfterFailsSuite`](junit-6.1.3/src/test/java/com/example/junit6/AfterFailsSuite.java) –
  подготовка и тест успешны, исключение бросает `@AfterSuite`.

```powershell
cd junit-6.1.3
mvn -Dscenario=BeforeFailsSuite test
mvn -Dscenario=TestFailsSuite test
mvn -Dscenario=AfterFailsSuite test
```

Ожидаемые последовательности:

| Сценарий              | События                                          |
|-----------------------|--------------------------------------------------|
| Ошибка `@BeforeSuite` | `beforeSuite`, `afterSuite`; тест не выполняется |
| Ошибка теста          | `beforeSuite`, `test`, `afterSuite`              |
| Ошибка `@AfterSuite`  | `beforeSuite`, `test`, `afterSuite`              |

Во всех трёх случаях запуск ошибочный.

<a id="junit-5"></a>

## JUnit 5.14.4

Проект использует Jupiter 5.14.4 и Suite API/Engine из Platform 1.14.4.
[`BeforeFailsSuite`](junit-5.14.4/src/test/java/com/example/junit5/BeforeFailsSuite.java)
выбирает вложенный `SelectedCase`, но бросает исключение в `@BeforeSuite` до его
выполнения. Этот пример позволяет отдельно сопоставить ошибку подготовки с JUnit 6.
Сценариев ошибки самого теста и `@AfterSuite` в этом проекте нет.

```powershell
cd junit-5.14.4
mvn -Dscenario=BeforeFailsSuite test
```

Ожидаемые события:

```text
[EVENT] beforeSuite
[EVENT] afterSuite
```

Тест не выполняется, `@AfterSuite` вызывается, запуск остаётся ошибочным.

<a id="junit-4"></a>

## JUnit 4.13.2

Единый проект [`junit-4.13.2/`](junit-4.13.2/pom.xml) содержит три запускаемых
сценария. Два из них проверяют ошибку подготовки:

- [`BeforeClassFailsScenario`](junit-4.13.2/src/test/java/com/example/junit4/BeforeClassFailsScenario.java) – исключение из `@BeforeClass` обычного тестового класса;
- [`BeforeClassFailsSuite`](junit-4.13.2/src/test/java/com/example/junit4/BeforeClassFailsSuite.java) – исключение из `@BeforeClass` набора с `@RunWith(Suite.class)`.

```powershell
cd junit-4.13.2
mvn -Dscenario=BeforeClassFailsScenario test
mvn -Dscenario=BeforeClassFailsSuite test
```

| Сценарий      | События                                 | Результат                                                       |
|---------------|-----------------------------------------|-----------------------------------------------------------------|
| Обычный класс | `beforeClass`, `afterClass`             | Тест не выполняется, `@AfterClass` вызывается                   |
| Класс набора  | `suite.beforeClass`, `suite.afterClass` | Выбранный класс не выполняется, `@AfterClass` набора вызывается |

Во втором сценарии отсутствуют также события `selected.beforeClass` и
`selected.afterClass`: жизненный цикл выбранного класса не начинается.
Обе команды завершаются с ошибкой из `@BeforeClass`.

Это поведение согласуется с [AfterClass (JUnit 4.13.2 API)](https://junit.org/junit4/javadoc/4.13.2/org/junit/AfterClass.html):
документация явно гарантирует вызов `@AfterClass` даже при исключении из `@BeforeClass`.

Третий сценарий – [`ClassRuleOrderTest`](junit-4.13.2/src/test/java/com/example/junit4/ClassRuleOrderTest.java).
Он программно запускает вспомогательный набор
[`OrderedClassRulesSuite`](junit-4.13.2/src/test/java/com/example/junit4/OrderedClassRulesSuite.java)
через `JUnitCore` и выполняет assertions над успешностью запуска и точным порядком
событий двух `@ClassRule`: внешнего с `order = 0` и внутреннего с `order = 1`.
Таким образом, в проекте четыре Java-файла: три запускаемых сценария и один
вспомогательный набор.

Из папки `junit-4.13.2/`:

```powershell
mvn -q -Dscenario=ClassRuleOrderTest test
```

Ожидаемый вывод:

```text
[EVENTS] [outer.before, inner.before, test, inner.after, outer.after]
```

Эта команда завершается успешно (код 0). JUnit 4.13.2 применяет отдельно
аннотированные class rules в заданной вложенности: большее значение `order`
соответствует внутреннему rule. Проверка порядка сохранена как дополнительный
технический пример; эта подробность не включается в публикуемую статью.

[Вернуться к содержанию](#contents)

<a id="testng"></a>

## TestNG 7.12.0

Проект содержит четыре независимых класса, каждый запускается отдельно:

- [`BeforeFailsWithoutAlwaysRunScenario`](testng-7.12.0/src/test/java/com/example/testng/BeforeFailsWithoutAlwaysRunScenario.java) –
  исключение в `@BeforeSuite`; тест и обычный `@AfterSuite` пропускаются.
- [`BeforeFailsWithAlwaysRunScenario`](testng-7.12.0/src/test/java/com/example/testng/BeforeFailsWithAlwaysRunScenario.java) –
  то же исключение, но `@AfterSuite(alwaysRun = true)` выполняется.
- [`TestFailsScenario`](testng-7.12.0/src/test/java/com/example/testng/TestFailsScenario.java) –
  подготовка успешна, тест вызывает `fail(...)`, обычный `@AfterSuite` выполняется.
- [`AfterFailsScenario`](testng-7.12.0/src/test/java/com/example/testng/AfterFailsScenario.java) –
  подготовка и тест успешны, исключение бросает обычный `@AfterSuite`.

```powershell
cd testng-7.12.0
mvn -Dscenario=BeforeFailsWithoutAlwaysRunScenario test
mvn -Dscenario=BeforeFailsWithAlwaysRunScenario test
mvn -Dscenario=TestFailsScenario test
mvn -Dscenario=AfterFailsScenario test
```

Ожидаемые последовательности:

| Сценарий                                               | События                                                   |
|--------------------------------------------------------|-----------------------------------------------------------|
| Ошибка `@BeforeSuite`, обычный `@AfterSuite`           | только `beforeSuite`; тест и `@AfterSuite` не выполняются |
| Ошибка `@BeforeSuite`, `@AfterSuite(alwaysRun = true)` | `beforeSuite`, `afterSuite`; тест не выполняется          |
| Ошибка теста                                           | `beforeSuite`, `test`, `afterSuite`                       |
| Ошибка `@AfterSuite`                                   | `beforeSuite`, `test`, `afterSuite`                       |

Во всех четырёх случаях запуск ошибочный.

<a id="scope"></a>

## Граница вывода

Результаты JUnit 5/6 фиксируют наблюдаемое поведение указанных версий. Javadocs
`@BeforeSuite` и `@AfterSuite` не формулируют отдельную гарантию для исключения из
`@BeforeSuite`, поэтому эксперимент не следует представлять как бессрочный контракт
всех будущих версий. Для TestNG поведение `alwaysRun` дополнительно описано в
официальной документации.

<a id="verification-2026-10-26"></a>

## Повторная проверка 26 октября 2026 года

На JDK 21.0.10, Maven 3.9.12 и Surefire 3.6.0 отдельно выполнены шесть сценариев
ошибки подготовки: два для JUnit 4.13.2, по одному для JUnit 5.14.4 и 6.1.3,
два для TestNG 7.12.0 (с `alwaysRun = true` и без него). Последовательности
`[EVENT]` совпали с указанными выше; событие `test` отсутствовало во всех шести.
Каждая команда вернула код 1 из-за намеренного исключения в подготовке.

После объединения проектов JUnit 4 отдельно повторены обе проверки ошибки
`@BeforeClass` и `ClassRuleOrderTest`. Первые две сохранили ожидаемые события и
код 1, проверка порядка Rules завершилась с кодом 0 и ожидаемой вложенностью.

Surefire может показывать `Tests run: 1` для синтетического `initializationError`
в JUnit. Это не означает, что тело выбранного теста выполнилось: в этих сценариях
оно печатает `[EVENT] test`, которого нет в выводе. В TestNG тест помечается
пропущенным. XML-отчёты находятся в `target/surefire-reports/` соответствующего проекта;
при повторных запусках отчёты могут перезаписываться или оставаться от прежних сценариев.

<a id="license"></a>

## Лицензия

Код и сопроводительная документация распространяются по [MIT License](LICENSE).
Авторское уведомление сохранено из исходного репозитория: Copyright (c) 2021 Andrii Olieinik.
JUnit, TestNG и другие зависимости распространяются по собственным лицензиям.
