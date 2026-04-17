
<?php
if ($_SERVER['REQUEST_METHOD'] == 'POST') {
    $target = "upload/" . basename($_FILES['file']['name']);
    move_uploaded_file($_FILES['file']['tmp_name'], $target);
    echo "Fichier uploadé";
}
?>

<form method="POST" enctype="multipart/form-data">
    <input type="file" name="file">
    <input type="submit" value="Upload">
</form>
