# embedding_system721
請依照以下順序執行程式:  
# 第一個要執行的程式-changeMinorSequence.py  
  這個程式是把csv檔案裡面的minor，依照大小順序從低到高排列。如此輸出的row就會剛好對應第幾個beacon，如row1對應beacon1。  
  此程式要改的地方有:input_file、output_file兩個變數  
# 第二個要執行的程式-read_write_version1 或version2:  
  這個程式是會根據時間把需要的資料抓出來，並且計算平均rssi，最後會存到一個excel檔裡面。  
  此程式要改的地方有:file_path、output_path、time_ranges 三個，其中time_ranges需要根據當天量測的數據來填入對應的時間。  
# 第三個要執行的程式-pathLossModel.py:  
  這個程式會把平均的rssi算出來，並且會把平均的path loss 係數算出來，顯示在螢幕上。此程式不會輸出csv檔。  
  此程式要改的地方有:target_points、csv_file  
