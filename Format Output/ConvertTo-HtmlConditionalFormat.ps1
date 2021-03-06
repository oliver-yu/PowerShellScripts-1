function ConvertTo-HtmlConditionalFormat{
     <#    
        .SYNOPSIS
            Function to convert PowerShell objects into an HTML table with the option to format individual table cells based on property values using CSS selectors.
        .DESCRIPTION
            Individual table cells can be formatted using a hashtable with one or multiple condition (of property to be met)/Property/css style to apply. (see example)
	    .PARAMETER InputObject
		    The object(s) to convert into a HTML table (no pipeline input).
	    .PARAMETER ConditionalFormat
		    A hashtable with entries following the following format (see example):
            - Key = Predicate representing the condition as string
            - Value = String array with two entries
              - Property to be formatted
              - Format as CSS selector
	    .EXAMPLE
		    $Path="$env:TEMP\test.html"
            #build the hashtable with Condition (of property to be met)/Property/css style to apply
            $ht=@{}
            $upperLimit=1000
            $ht.Add("[int]`$_.Value -gt $upperLimit",("Handles","color:green;font-weight: bold"))
            $ht.Add('[int]$_.Value -lt 50',("Handles","background-color:red"))
            $ht.Add('$_.Value -eq "rundll32"',("Name","background-color:blue"))
            ConvertTo-HtmlConditionalFormat (Get-Process | select Name, Handles) $ht $Path -open
	    .EXAMPLE
		    $Path="$env:TEMP\test.html"
            #build the hashtable with Condition (of property to be met)/Property/css style to apply
            $ht=@{}
            $ht.Add('$_.Value -eq ".txt"',("Extension","background-color:blue"))
            $ht.Add('$_.Value -eq ".bmp"',("Extension","background-color:red"))
            ConvertTo-HtmlConditionalFormat (dir | select FullName,Extension,Length,LastWriteTime) $ht $Path -open
        .EXAMPLE
            $Path="$env:TEMP\test.html" 
            #create some test object with a 'Compliant' property
            $WindowsFeaturesCompliance = 
                foreach ($i in 1..10){
                    $compliance = "***NON COMPLIANT***"
                    if ($i % 2){
                        $compliance = "Compliant"
                    }
                    New-Object PSObject -Property @{'ItemNumber'=$i;'Compliant'=$compliance}
                }
            $ht=@{}
            $NonCompliant = "***NON COMPLIANT***"
            $ht.Add("`$_.Value -like '$NonCompliant'",("Compliant","color:Red;font-weight: bold")) 
            ConvertTo-HtmlConditionalFormat ($WindowsFeaturesCompliance) $ht $Path -open
        .LINK
            http://stackoverflow.com/questions/4559233/technique-for-selectively-formatting-data-in-a-powershell-pipeline-and-output-as
    #>
	param(
		$InputObject,
		[System.Collections.Hashtable]$ConditionalFormat,
		$Path,
		[switch]$Open
	)
	Add-Type -AssemblyName System.Xml.Linq
	$xml = [System.Xml.Linq.XDocument]::Parse( "$($InputObject | ConvertTo-Html)" )
	$ns='http://www.w3.org/1999/xhtml'
	$cells = $xml.Descendants("{$ns}td")
	foreach($key in $ConditionalFormat.Keys){
		$sb=[scriptblock]::Create($key)
		$colIndex = (($xml.Descendants("{$ns}th") | Where-Object { $_.Value -eq $ConditionalFormat.$key[0] }).NodesBeforeSelf() | Measure-Object).Count
		$cells | Where-Object { ($_.NodesBeforeSelf() | Measure-Object).Count -eq $colIndex} | ForEach-Object {
			if(&$sb){
				$_.SetAttributeValue( "style", $ConditionalFormat.$key[1])
			}
		}
	}
	$xml.Save("$Path")

	if ($Open){
		Invoke-Item $Path
	}
}
