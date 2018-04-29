get-module -listavailable | where-object { $_.Name -eq "Azure" } | select Version, Name, Author | FT
