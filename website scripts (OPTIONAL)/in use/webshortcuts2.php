<html>
 <head>
  <title>Script by Franc1sco franug</title>
 </head>
 <body oncontextmenu="return false" onkeydown="return false">
<?php
function dameURL(){
$url="https://".$_SERVER['HTTP_HOST'].$_SERVER['REQUEST_URI'];
return $url;
}

        $url2=DameURL();

        $url_final = str_replace("https://go-free.info/webshortcuts2.php?web=", "", $url2);
        $url_final2 = str_replace("https://go-free.info/webshortcuts2.php?web=", "", $url_final);
        $trozo = explode(";franug_is_pro;", $url_final2);

        //echo $url_final;
?>
<script type="text/javascript">
        var popup=window.open("<?php echo $trozo[1]; ?>","Script by Franc1sco franug","<?php echo $trozo[0]; ?>");
        // my script ;)
</script>
 </body>
</html>