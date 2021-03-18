function get-adobeflashversion{
    try{
        $flashobject = new-object -ComObject "shockwaveflash.shockwaveflash"
        $version=(($flashobject.getvariable("`$version")).replace(",",".")).trimstart("WIN ")
    }
    Catch{
        write-warning "Could not create Com Object, are you sure Adobe Flash is installed?"
    }
    return $version
}
get-adobeflashversion

#https://andymorgan.wordpress.com/2012/01/09/retrieve-adobe-flash-version-with-powershell/