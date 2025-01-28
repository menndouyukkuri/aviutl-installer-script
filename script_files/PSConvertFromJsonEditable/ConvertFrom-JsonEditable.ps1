using namespace System.Management.Automation
using namespace System.Collections
using namespace System.Collections.Generic


function ConvertValuesInObjectToHashtable {
    <#
    .SYNOPSIS
        オブジェクトの要素もしくはプロパティの値をハッシュテーブルに変換する。
    .DESCRIPTION
        引数の型によって動作を変える。
        - PSCustomObject型のオブジェクト
            - 各プロパティ名をKey、値をValueとしてハッシュテーブルにする。
        - Array型のオブジェクト
            - 各要素のインデックスをKey、値をValueとしてハッシュテーブルにする。
        - それ以外は空ハッシュテーブルとする。
    .PARAMETER InputObject
        Object型のオブジェクト
    .OUTPUTS
        Hashtable.
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [object]
        $InputObject
    )
    $hash = [ordered]@{}
    if ($InputObject -is [IDictionary] ) {
        $InputObject.Keys | ForEach-Object { $hash.Add($_,$InputObject[$_])}
    }elseif ($InputObject -is [IEnumerable] -and $InputObject -isnot [string]) {
        for ($i = 0; $i -lt $InputObject.Count; $i++) {
            $hash.Add($i, $InputObject[$i])
        }
    }
    elseif ($InputObject -is [PSCustomObject]) {
        $InputObject.PSObject.Properties | ForEach-Object { $hash.Add($_.Name, $_.Value) }
    }
    
    return $hash
}

function AddGetDepthMethod {
    param (
        [Parameter(Mandatory)]
        [object]
        $InputObject
    )
    if ($InputObject -is [ValueType] -or $InputObject -is [string]) {
        throw "対象外のオブジェクトです。"
    }

    # オブジェクトに深さ取得のオブジェクトを追加する。
    Add-Member -InputObject $InputObject -MemberType ScriptMethod -Name GetDepth -Value {
        param()
        CalcDepth -InputObject $this
    }
}

function ConvertJsonObjectToEditableJson {
    <#
    .SYNOPSIS
        オブジェクトをハッシュテーブルもしくは配列に変換する。
    .DESCRIPTION

    .PARAMETER InputObject
        Object型のオブジェクト
    .OUTPUTS
        object[].
    #>
    param (
        [parameter(Mandatory)]
        [Object]$InputObject
    )

    if ($InputObject -is [ValueType] -or $InputObject -is [string]) {
        throw "対応していない引数の型です。"
    }

    $dict = ConvertValuesInObjectToHashtable -InputObject $InputObject
    $table = [ordered]@{}
    foreach ($kvp in $dict.GetEnumerator()) {
        $addValue = $kvp.Value
        if ($kvp.Value -is [PSCustomObject] -or $kvp.Value -is [Array]) {
            $addValue = ConvertJsonObjectToEditableJson -InputObject $kvp.Value
        }
        $table.Add($kvp.Key, $addValue)
    }
    # 入力が配列の場合、ハッシュテーブルを配列に変更する。
    if ($InputObject -is [Array]) {
        $table = [List[Object]]@( $table.Keys | Sort-Object | ForEach-Object { ,$table[$_] })
    }

    AddGetDepthMethod -InputObject $table
    # 配列の場合を考慮し、アンボクシングを防ぐ
    return , $table
}

function CalcDepth {
    <#
    .SYNOPSIS
        入れ子の深さを算出する。
    .DESCRIPTION
        引数のオブジェクトが持つ要素（プロパティ／以下の条件を入れ子と判断し、再帰的に本関数を実行する。
        - InputObjectがPSCustomObject型
        - InputObjectがIDictionary型
        - InputObjectが文字列以外のIEnumerable型

    .PARAMETER InputObject
        Object型のオブジェクト
    .OUTPUTS
        int型の入れ子の深さ.
    #>
    param (
        [Parameter(Mandatory)]
        [Object]
        $InputObject
    )
    if ($null -eq $InputObject) {
        throw "引数が不正です。"
    }
    [int]$maxDepth = 0
    [int]$tempDepth = 0
    [Hashtable]$hashtable = ConvertValuesInObjectToHashtable -InputObject $InputObject
    foreach ($value in $hashtable.Values) {
        if ($value -is [PSCustomObject] -or 
            $Value -is [IDictionary] -or
            $Value -is [IEnumerable] -and $Value -isnot [string]) {
            $tempDepth = CalcDepth -InputObject $value
        }
        $maxDepth = [System.Math]::Max($maxDepth, $tempDepth)
    }
    return (1 + $maxDepth)
}

function ConvertFrom-JsonEditable {
    <#
    .SYNOPSIS
        JSON文字列から編集できるJSON型オブジェクトを生成する。
    .DESCRIPTION
        ConvertFrom-Jsonコマンド利用するため、それがエラーを起こす入力は同様にエラーを発生させる。
    .PARAMETER Value
        文字列のJSON
    .OUTPUTS
        [OrderedDictionary] | [Array]
    #>
    param (
        [Parameter(Mandatory, ValueFromPipeline = $true)]
        [Array]
        $Value
    )

    # パイプライン用
    Begin {
        $jsonText = ""
    }
    Process {
        $jsonText += $Value
    }
    End {
        if (-not $jsonText) {
            throw "JSON文字列がnullもしくは空文字です。"
        }
        try {
            $json = ConvertFrom-Json -InputObject $jsonText
            $object = ConvertJsonObjectToEditableJson -InputObject $json
            return ,$object
        }
        catch {
            if (-not $json) {
                Throw "ConvertFrom-Jsonエラー：JSONの形式を確認してください。"
            }
            Throw $_
        }
    }
}
