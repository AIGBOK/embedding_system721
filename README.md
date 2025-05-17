# embedding_system721
程式分為訓練模式、跟計算位置模式，請依照以下順序執行程式:  
# 訓練模式
## 第一個要執行的程式-changeMinorSequence.py  
  這個程式是把csv檔案裡面的minor，依照大小順序從低到高排列。如此輸出的row就會剛好對應第幾個beacon，如row1對應beacon1。  
  此程式要改的地方有:input_file、output_file兩個變數  
## 第二個要執行的程式-read_write_version3:  
  這個程式是會根據時間把需要的資料抓出來，會直接計算P0、path loss係數，最後會存到一個excel檔裡面。  
  此程式要改的地方有:file_path、output_path、time_ranges 三個，其中time_ranges需要根據當天量測的數據來填入對應的時間，並且time ranges都是對著beacon那個方位的時間，並且time ranges必須照著beacon 1、2、3、4的順序排列。  
# 計算位置模式
## 第一個要執行的程式: read_write_version1.py
  這個程式要改time_ranges，把我們用來測試的資料點的時間寫上去。file_path、output_path也記得要改。
  這個程式會輸出某一個測資對於四個beacon的rssi。
## 第二個要執行的程式: countPoistion.py
  這個程式要改的地方有:p_db0、p_dbtest、path_loss_coff、以及下面的x1,y1~x3、y3
  這個程式會直接跑出預測的使用者座標。
