<html>
<head>
    <title>
        Order Status
    </title>
    <style>
        body{
            background-color: aliceblue;
        }
        h1{
            color: green;
            text-align: center;
        }
    </style>
</head>
<body>
<h1>Order Status</h1>
<form>
    <?php
    $target_dir="uploads/";
    $target_file = $target_dir . basename($_FILES["uploadFile"]["name"]);
    $uploadOk = 1;
    $fileType = pathinfo($target_file, PATHINFO_EXTENSION);

    // Check if file already exists
    if(file_exists($target_file)){
        echo "Sorry, file already exists.";
        $uploadOk = 0;
    }

    // Check file size
    if($_FILES["uploadFile"]["size"] > 5000000){
        echo "Sorry, your file is too large.";
        $uploadOk = 0;
    }

    // Restricted file formats
    if($fileType != "txt"){
        echo "Sorry, only text files are allowed.";
        $uploadOk = 0;
    }

    // Check if $uploadOk is set to 0 by an error
    if($uploadOk == 0){
        echo "<pre>Sorry, your file was not uploaded</pre>";
        // if everything is ok, try to upload file
    } else {
        if(move_uploaded_file($_FILES["uploadFile"]["tmp_name"], $target_file)){
            //chmod($target_file, 0777);
            echo "File ". basename($_FILES["uploadFile"]["name"]). " uploaded successfully.";
            //$output = shell_exec("./order.sh");
            $output = shell_exec("./order.sh ./$target_file");
            echo ("<pre>$output</pre>\n");

        }else{
            echo "Sorry, there was an error uploading your file.";
        }
    }
    ?>
    <a href="Order.html" title="Back to the Home Page"><b>Home</b></a>
</form>
</body>
</html>



