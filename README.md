# RPS

## อธิบายโค้ดที่ป้องกันการ lock เงินไว้ใน contract
![image](https://github.com/user-attachments/assets/45a4c209-1a22-4e3f-9036-57061f3a14e3)
เมื่อผู้เล่นครบสองคน เราจะเริ่มนับเวลาจากตอนที่ผู้เล่นเริ่ม commit ครั้งแรก ถ้าอีกคนยังไม่ commit ภายใน 1 นาที สามารถยกเลิกเกมได้และจะได้รับเงินคืนทั้งคู่

## อธิบายโค้ดส่วนที่ทำการซ่อน choice และ commit

![image](https://github.com/user-attachments/assets/695ab91e-a884-4d91-9a4f-660e6db8b7f5)

ในส่วนนี้เราจะนำ choice ไป concatenate กับ random bit จากนั้นนำมาใช้เป็น input เพื่อนำไปเข้า hash function แล้วเราจะนำค่าที่เป็นผลลัพธ์มาใช้ในการ commit ซึ่งเราจะแก้ hash function จากผลลัพธ์ไปหา input ได้ยาก

## อธิบายโค้ดส่วนที่จัดการกับความล่าช้าที่ผู้เล่นไม่ครบทั้งสองคนเสียที
![image](https://github.com/user-attachments/assets/3fffb137-8a24-4ebf-94e3-3d210fe36ae6)
มี function refundMatching ที่ตรวจสอบว่าถ้ามี ผู้เล่น 1 คน และ เวลาได้ผ่านไป 1 นาทีจากเวลาที่ผู้เล่นคนนี้เข้าร่วม จะสามารถยกเลิกและขอเงินคืนได้

## อธิบายโค้ดส่วนทำการ reveal และนำ choice มาตัดสินผู้ชนะ 

![image](https://github.com/user-attachments/assets/97ef68b4-f2d1-45c7-b979-303e7f7c77f9)

ในส่วนนี้จะเช็คว่าค่า commit เป็นค่าที่ออกมาจาก hash function ที่เราใส่ choice ไปจริงๆ ซึ่งถ้าจริง เราจะนำมาคิดค่า choice จาก byte สุดท้ายแล้วนำไปเข้า function _checkWinnerAndPay ซึ่งจะตัดสินผู้ชนะได้
