import os

def scandir(path=None, relative_path=""):

    if path is None or not os.path.isdir(path):
        return None

    dir_list = os.listdir(path)
    current_tree = {}

    for entry in dir_list:
        abs_path = os.path.join(path, entry)
        upload_path = os.path.join(relative_path, entry)
        if os.path.isfile(abs_path):
            current_item = {
                "type" : "file",
                "abs_path" : abs_path,
                "upload_path" : upload_path
            }
            current_tree[entry] = current_item

        elif os.path.isdir(abs_path):
            current_item_dir_list = scandir(abs_path, upload_path)
            current_item = {
                "type" : "dir",
                "abs_path" : abs_path,
                "dir_list" : current_item_dir_list
            }
            current_tree[entry] = current_item

    return current_tree
