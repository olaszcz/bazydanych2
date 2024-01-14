<#
    Script Name: Projekt_bazydanych.ps1
    Description: Skrypt przeznaczony do walidacji pliku.
    Author: Aleksandra Szczech
    Date Created: 14.01.2024
    Change Log:
        - Version 1.0 (14.01.2024): Initial script creation.
#>

# ZAD 1.
# Sciezka do pliku oraz haslo
param (
    [string]$zipUrl = "http://home.agh.edu.pl/~wsarlej/dyd/bdp2/materialy/cw10/InternetSales_new.zip",
    [string]$password = "bdp2agh"
)
# Ścieżka docelowa dla pobranego pliku
$download = "$env:USERPROFILE\InternetSales_new.zip"

# Ścieżka docelowa dla rozpakowanego pliku
$extracted =  "$env:USERPROFILE\"

# Ścieżka do 7-Zip (odpowiednią dla systemu)
$zip = "C:\Program Files\7-Zip\7z.exe"

#
$timestamp = Get-Date -Format "yyyyMMddHHmmss"

$processed = "$env:USERPROFILE\PROCESSED"

# Utworzenie katalogu "PROCESSED", jeśli nie istnieje
if (-not (Test-Path $processed -PathType Container)) {
    New-Item -Path $processed -ItemType Directory
    }

# Utworzenie ścieżki do pliku logu
$log = "$env:USERPROFILE\PROCESSED\Projekt1_${timestamp}.log"


# Funkcja do logowania
function LogEvent {
    param(
        [string]$step,
        [string]$status
    )

    $logMessage = "$((Get-Date -Format "yyyyMMddHHmmss")) - $step - $status"
    Add-Content -Path $log -Value $logMessage
    Write-Output $logMessage
}

# A. Pobieranie pliku
try {
    Invoke-WebRequest -Uri $zipUrl -OutFile $download
    LogEvent "Downloading Step" "Successful"
}
catch {
    LogEvent "Downloading Step" "Failed"
    exit 1
}

# B. Rozpakowywanie pliku
try {
    & $zip x $download "-o$extracted" "-p$password"
    LogEvent "Extracting Step" "Successful"
}
catch {
    LogEvent "Extracting Step" "Failed"
    exit 1
}

# C. Sprawdzenie poprawności pliku
# Plik z blednymi wierszami:
$badFile = "$env:USERPROFILE\InternetSales_new.bad_${timestamp}.txt"
# liczba kolumn
$Columns = (Get-Content "$env:USERPROFILE\InternetSales_new.txt" -TotalCount 1) -split '\|' | Measure-Object | Select-Object -ExpandProperty Count
$file = "$env:USERPROFILE\InternetSales_new.txt"
$headers = Get-Content $file -TotalCount 1

# Utworzenie pustego pliku bad
    $null | Out-File -file $badFile
    $uniqueLines = New-Object System.Collections.Generic.List[string]

 try {
 # Sprawdzenie i zapisanie: wiersze z niepoprawnym formatem w kolumnie Customer_Name
    (Get-Content $file) | ForEach-Object {
        $columns = $_ -split '\|'
                 if ($columns[-1] -ne '') {
            # Przenieś wiersz do folderu złych danych
                Add-Content -Path $badFile -Value $_
                return
            }
        # Sprawdzenie, czy kolumna Customer_Name nie jest pusta
        if ($columns[2] -ne '') {
            $nameParts = $columns[2] -split ','
            $nameParts = $columns[2] -replace '^"|"$' -split ','

            # Sprawdzenie, czy pierwsza część składa się z dwóch takich samych wyrazów
            $namePartsWords = $nameParts[0] -split '-'
            if ($namePartsWords[0] -eq $namePartsWords[1]) {
                # Jeśli warunek spełniony, zapisz wiersz do pliku błędów
                Add-Content -Path $badFile -Value $_
                return
            }
        }

                # Sprawdź, czy wartość jest w formacie "nazwisko,imie"
        if ($columns[2] -notmatch '^[^,]+,[^,]+$') {
            # Jeśli wartość nie jest w poprawnym formacie, zapisz wiersz do pliku błędów
            Add-Content -Path $badFile -Value $_
            return
        }

        # Jeśli wszystko jest w porządku, zapisz wiersz z powrotem do pliku
        $line = $columns -join '|'
        $line
    } | Out-File -FilePath $file -Force



    # folder istnieje
    if (-not (Test-Path -Path $extracted -PathType Container)) {
        New-Item -Path $extracted -ItemType Directory
    }

    # liczba kolumn w pliku 
    $ColCount = (Get-Content $file -TotalCount 1) -split '\|' | Measure-Object | Select-Object -ExpandProperty Count
    $rows = Get-Content $file | Select-Object -Skip 1

    # ilość kolumn taką jak nagłówek pliku
    $badRows = $rows | Where-Object { ($_ -split '\|' | Measure-Object | Select-Object -ExpandProperty Count) -ne $ColCount }

    # błędne wiersze do pliku
    $badRows | Out-File -file $badFile -Append

    # poprawne wiersze do pliku tymczasowego
    $tempfile = [System.IO.Path]::GetTempFileName()
    $headers | Out-File -file $tempfile
    $rows | Where-Object { ($_ -split '\|' | Measure-Object | Select-Object -ExpandProperty Count) -eq $ColCount } | Out-File -file $tempfile -Append
    Move-Item -Path $tempfile -Destination $file -Force

    # dwie kolumny
    $content = Get-Content $file

    # FIRST_NAME, LAST_NAME
    $firstLine = $content[0] -split '\|'
    $firstLine += "FIRST_NAME", "LAST_NAME"
    $newFirstLine = $firstLine -join '|'

    # zamiana pierwszej linii z podmienioną
    $content[0] = $newFirstLine

    # Każda linia
    $content | ForEach-Object {
        $columns = $_ -split '\|'

        # czy kolumna Customer_Name nie jest pusta i ma poprawny format
        if ($columns[2] -ne '' -and $columns[2] -match '^[^,]+,[^,]+$') {
            # Customer_Name na dwie osobne kolumny
            $firstLastName = $columns[2] -split ','
            $columns += $firstLastName[1].Trim(), $firstLastName[0].Trim()
        }

        $line = $columns -join '|'
        $line -replace '"', ''  
    } | Out-File -file $file -Force

   # plik tymczasowy na duplikaty
   $tempFile = "$env:USERPROFILE\duplikaty.txt"
    $all = Get-Content $file

    # Znajdowanie duplikatów
    $all | Group-Object | Where-Object { $_.Count -gt 1 } | ForEach-Object {
        $duplicateRows = $_.Group

        # jedno wystąpienie każdego duplikatu do pliku błędów
        $duplicateRows | Select-Object -Skip 1 | Out-File -FilePath $badFile -Append
        $duplicateRows | Select-Object -Skip 1 | Out-File -FilePath $tempFile -Append
        $all = $all | Where-Object { $_ -notin $duplicateRows }

    }


    # Zapiszanie zmodyfikowanych danych (z jednym wystąpieniem każdego duplikatu) z powrotem do głównego pliku
    $all | Out-File -FilePath $file -Force
    $d = Get-Content $tempFile
   
    # puste wiersze 
    $empty = $all | Where-Object { $_ -eq '' }
    $empty | Out-File -file $badFile -Append

    # wartości w OrderQuality > 100:
    $maxOrder = 100
    $badOrder = $all | Where-Object { $_ -notmatch 'ProductKey' -and [int]($_ -split '\|')[4] -gt $maxOrder }
    $badOrder | Out-File -file $badFile -Append
    $all = $all | Where-Object { $_ -ne '' -and ($_ -match 'ProductKey' -or [int]($_ -split '\|')[4] -le $maxOrder) }

    # nadpisanie wartości
    $all, $d | Out-File -file $file -Force
    
    Remove-Item "$tempFile" -Force

   LogEvent "Modification" "Successful"
}
catch {
    LogEvent "Modification" "Failed"
    exit 1
}

# D. W bazie MySQL utworzenie tabeli CUSTOMERS_${NUMERINDEKSU}
try{
# Parametry bazy danych:
$databaseServer = "OLA\SQLDEV"  
$databaseName = "AdventureWorksDW2019"
$databaseUser = "ola\osz05"
Import-Module SqlServer
$NUMERINDEKSU = "402687"

# Połączenie z bazą
$connectionString = "Server=$databaseServer;Database=$databaseName;Integrated Security=True;"
$connection = New-Object System.Data.SqlClient.SqlConnection
$connection.ConnectionString = $connectionString
$connection.Open()

# Tabela Customers
$tableCreationQuery = @"
USE $databaseName;

CREATE TABLE CUSTOMERS_${NUMERINDEKSU} (
    ProductKey INT,
    CurrencyAlternateKey NVARCHAR(3),
    Customer_Name NVARCHAR(255),
    OrderDateKey INT,
    OrderQuantity INT,
    UnitPrice DECIMAL(10,2),
    SecretCode NVARCHAR(50),
    FIRST_NAME NVARCHAR(50),
    LAST_NAME NVARCHAR(50)
);
"@
$createCommand = $connection.CreateCommand()
$createCommand.CommandText = $tableCreationQuery
$createCommand.ExecuteNonQuery()
$tableName = "CUSTOMERS_${NUMERINDEKSU}"

LogEvent "Table created" "Successful"
}

catch {
    LogEvent "Table created" "Failed"
    exit 1
}

# E. Załadowanie danych ze zweryfikowanego pliku do tabeli
try{

$data = Get-Content $file
# Utworzenie kolumn w tabeli:
$dataTable = New-Object System.Data.DataTable
$dataTable.Columns.Add("ProductKey", [System.Int32])
$dataTable.Columns.Add("CurrencyAlternateKey", [System.String])
$dataTable.Columns.Add("Customer_Name", [System.String])
$dataTable.Columns.Add("OrderDateKey", [System.Int32])
$dataTable.Columns.Add("OrderQuantity", [System.Int32])
$dataTable.Columns.Add("UnitPrice", [System.Decimal])
$dataTable.Columns.Add("SecretCode", [System.String])
$dataTable.Columns.Add("FIRST_NAME", [System.String])
$dataTable.Columns.Add("LAST_NAME", [System.String])

#przejscie przez każdą linię w pliku, rozdzielenie kązdej liniina podstawie zanku '|'
foreach ($line in $data) {
    $values = $line -split '\|'
    $row = $dataTable.NewRow()


    try {
        $row["ProductKey"] = [int]$values[0]
        $row["CurrencyAlternateKey"] = $values[1]
        $row["Customer_Name"] = $values[2]
        $row["OrderDateKey"] = [int]$values[3]
        $row["OrderQuantity"] = [int]$values[4]
        $row["UnitPrice"] = [decimal]$values[5]/100
        $row["SecretCode"] = $values[6]
        $row["FIRST_NAME"] = $values[7]
        $row["LAST_NAME"] = $values[8]
        $dataTable.Rows.Add($row) # dodanie wiersza do tabeli
    } catch {
        Write-Host "Error converting values: $_"
    }
}
# Ścieżka do plików tymczasowych
$file_tab = "$env:USERPROFILE\tabela.txt"
$file_tab2 = "$env:USERPROFILE\tabela2.txt"
$format = "$env:USERPROFILE\format.xml"

$dataTable | ForEach-Object { $_.ItemArray -join "`t" } | Out-File -file $file_tab
$lines = Get-Content $file_tab

# Zmodyfikowanie odpowiedniej kolumny 
for ($i = 0; $i -lt $lines.Count; $i++) {
    $columns = $lines[$i] -split '\t' 
    for ($j = 0; $j -lt $columns.Count; $j++) {
        if ($j -ne 2) {  
            $columns[$j] = $columns[$j] -replace ',', '.'
        }
    }

    $lines[$i] = $columns -join "`t"
}

$lines | Out-File -file $file_tab2 -Force
$baza = "AdventureWorksDW2019.dbo.CUSTOMERS_402687"
$bcpCommand= @"
bcp $baza IN $file_tab2 -T -S $databaseServer -f $format -w
"@ 
Invoke-Expression $bcpCommand

# usuniecie plikow tymczasowych
Remove-Item "$file_tab" -Force
Remove-Item "$file_tab2" -Force
LogEvent "Load data" "Successful"
}

catch {
    LogEvent "Load data" "Failed"
    exit 1
}

# F. przeniesienie przetworzonego pliku do podkatalogu PROCESSED 
try{
# Pobieranie nazwy pliku i rozszerzenia
$fileName = [System.IO.Path]::GetFileNameWithoutExtension($file)
$fileEx = [System.IO.Path]::GetExtension($file)
$newfile = Join-Path -Path $processed -ChildPath "${timestamp}_${fileName}${fileEx}"
Move-Item -Path $file -Destination $newfile

LogEvent "File transfer" "Successful"
}

catch {
    LogEvent "File transfer" "Failed"
    exit 1
}

# G. Aktualizacja kolumny SecretCode 
try{
# Generowanie losowego ciągu o długości 10
function Generate-RandomString {
    param([int]$length = 10)

    $characters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
    $random = Get-Random -Minimum 0 -Maximum $characters.Length

    $randomString = ""
    for ($i = 0; $i -lt $length; $i++) {
        $randomString += $characters[($random + $i) % $characters.Length]
    }

    return $randomString
}

$updateConnectionString = "Server=$databaseServer;Database=$databaseName;Integrated Security=True;"
$updateConnection = New-Object System.Data.SqlClient.SqlConnection
$updateConnection.ConnectionString = $updateConnectionString
$updateConnection.Open()

# losowy ciąg o długości 10
$randomString = Generate-RandomString -length 10

# Kwerenda SQL do aktualizacji kolumny SecretCode
$updateQuery = @"
UPDATE CUSTOMERS_${NUMERINDEKSU}
SET SecretCode = '$randomString'
"@

$updateCommand = $updateConnection.CreateCommand()
$updateCommand.CommandText = $updateQuery
$updateCommand.ExecuteNonQuery()
LogEvent "SecretCode Update" "Successful"
}

catch {
    LogEvent "SecretCode Update" "Failed"
    exit 1
}

# H. Wyeksportowanie zawartość tabeli CUSTOMERS_${NUMERINDEKSU} do pliku csv

try{
# Pobieranie danych z tabeli

$databaseServer = "OLA\SQLDEV"
$databaseName = "AdventureWorksDW2019"
$databaseUser = "ola\osz05"
$NUMERINDEKSU = "402687"

# Połączenie z bazą
$connectionString = "Server=$databaseServer;Database=$databaseName;Integrated Security=True;"
$connection = New-Object System.Data.SqlClient.SqlConnection
$connection.ConnectionString = $connectionString
$connection.Open()

$query = "SELECT * FROM CUSTOMERS_$NUMERINDEKSU"
$csvfile = "$([System.Environment]::GetFolderPath('Desktop'))\BAZY_PROJEKT_8_01\InternetSales_new_2.csv"

$adap = New-Object System.Data.SqlClient.SqlDataAdapter($query, $connection)
$dataSet = New-Object System.Data.DataSet
$adap.Fill($dataSet) | Out-Null

$connection.Close()

# Zapisanie danych do pliku CSV
$dataSet.Tables[0] | Export-Csv -Path $csvfile -NoTypeInformation

LogEvent "Export Table" "Successful"
}

catch {
    LogEvent "Export Table" "Failed"
    exit 1
}


# I. Skompresowanie pliku
try{
$compressed = "$([System.Environment]::GetFolderPath('Desktop'))\BAZY_PROJEKT_8_01\InternetSales_new_2.zip"
Compress-Archive -Path $csvfile -DestinationPath $compressed -Force
LogEvent "Compress File" "Successful"
}

catch {
    LogEvent "Compress File" "Failed"
    exit 1
}
