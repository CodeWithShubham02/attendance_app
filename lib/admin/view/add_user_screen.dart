import 'dart:io';

import 'package:aws_s3_api/s3-2006-03-01.dart';
import 'package:aws_s3_upload/aws_s3_upload.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:joizone/admin/controller/department_controller.dart';
import 'package:joizone/admin/controller/shift_controller.dart';
import 'package:joizone/admin/model/department_model.dart';
import 'package:joizone/admin/model/shift_model.dart';

import '../../handller/encription_decription.dart';
import '../controller/branch_controller.dart';
import '../controller/user_controller.dart';
import '../model/branch_model.dart';
import 'package:flutter/foundation.dart';

class AddUserScreen extends StatefulWidget {
  @override
  State<AddUserScreen> createState() => _AddUserScreenState();
}

class _AddUserScreenState extends State<AddUserScreen> {
  final UserController controller = UserController();

  final useridCtrl = TextEditingController();
  final passwordCtrl = TextEditingController();
  final nameCtrl = TextEditingController();
  final emailCtrl = TextEditingController();
  final phoneCtrl = TextEditingController();
  final fullAddressCtrl = TextEditingController();
  final genderCtrl=TextEditingController();
  String? selectedGender;
  bool loading = false;

  final UserController _controller1 = UserController();
  DateTime? selectedDate;
  TextEditingController dateController = TextEditingController();
  Future<void> submitUser() async {
    print("date of joing ${dateController}");
    // ✅ API format (yyyy-MM-dd)
    String apiDate = DateFormat('yyyy-MM-dd').format(selectedDate!);
    final success = await _controller1.createUser(
      cid: "1",
      userid: useridCtrl.text,
      password: passwordCtrl.text,
      userToken: "token_123",
      userImg: photoUrl ?? "",
      fullName: nameCtrl.text,
      userEmail: emailCtrl.text,
      userPhone: phoneCtrl.text,
      gender: genderCtrl.text,
      fullAddress: fullAddressCtrl.text,
      branchId: selectedBranchId ?? "",
      branchName: selectedBranchName ?? "",
      branchDistance: selectedBranchDistance ?? "",
      branchLat: selectedBranchLat ?? "",
      branchLong: selectedBranchLong ?? "",
      departmentId: selectedDepartId ?? "",
      departmentName: selectedDepartName ?? "",
      shiftId: selectedShiftId ?? "",
      shiftStart: selectedShiftStart ?? "",
      shiftEnd: selectedShiftEnd ?? "",
      dateOfJoining: apiDate, // DD-MM-YYYY or YYYY-MM-DD
      imeiNo: "",
    );
    print("date of joing $dateController");
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✅ User Created Successfully")),
      );
      Get.back();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("❌ User not created.")),
      );
    }
  }

  Future<void> selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      setState(() {
        selectedDate = picked;

        // ✅ UI format (dd-MM-yyyy)
        dateController.text =
            DateFormat('dd-MM-yyyy').format(picked);
      });
    }
  }
  //branch
  final BranchController _controller = BranchController();
  List<BranchModel> branchList = [];
  String? selectedBranchId;
  String? selectedBranchName;
  String? selectedBranchLat;
  String? selectedBranchLong;
  String? selectedBranchDistance;
  bool isLoading = false;

  //shift
  final ShiftController _shiftController=ShiftController();
  List<ShiftModel> shiftList=[];
  String? selectedShiftId;
  String? selectedShiftStart;
  String? selectedShiftEnd;
  bool isShiftLoading = false;

  //department
  final DepartmentController _departmentController=DepartmentController();
  List<DepartmentModel> departmentList=[];
  String? selectedDepartId;
  String? selectedDepartName;
  bool isDepartLoading=false;

  //photo
  bool isLoadingPhoto = false;
  File? photo;          // Mobile
  Uint8List? webPhoto; // Web
  String? photoUrl;     // Uploaded URL



  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    loadBranches();
    loadShift();
    loadDepartment();
  }
  final ImagePicker _picker = ImagePicker();

  Future<String?> pickImagePhoto1(ImageSource source) async {
    try {
      setState(() => isLoadingPhoto = true);

      final XFile? picked =
      await _picker.pickImage(source: source, imageQuality: 80);

      if (picked == null) {
        setState(() => isLoadingPhoto = false);
        return null;
      }

      final Uint8List bytes = await picked.readAsBytes();

      // 👇 local preview ke liye
      if (!kIsWeb) {
        photo = File(picked.path);
      } else {
        webPhoto = bytes;
      }

      setState(() {}); // preview refresh

      final fileName =
          "uploads/image_${DateTime.now().millisecondsSinceEpoch}.jpg";

      final imageUrl = await uploadImageToS3(
        imageBytes: bytes,
        bucket: "joizone-s3",
        objectKey: fileName,
      );

      photoUrl = imageUrl; // ✅ save public URL
      return imageUrl;
    } catch (e) {
      print("❌ Pick/Upload error: $e");
      return null;
    } finally {
      setState(() => isLoadingPhoto = false);
    }
  }

  Future<String> uploadImageToS3({
    required Uint8List imageBytes,
    required String bucket,
    required String objectKey,
    String region = 'ap-south-1',
  }) async {
    final s3 = S3(
      region: region,
      credentials: AwsClientCredentials(
        accessKey: decryptFMS(
          "TohPtOvObC8NnBOp/1BM30tSr97U803JZ+gqI3Jf4uM=",
          "QWRTEfnfdys635",
        ),
        secretKey: decryptFMS(
          "Exz2WIEt2w1JRVZREvtIPeRX5Jti2p2mcHqs7Hh87/47BQidFAUAkLOxlzYFlctw",
          "QWRTEfnfdys635",
        ),
      ),
    );

    await s3.putObject(
      bucket: bucket,
      key: objectKey,
      body: imageBytes,
      contentLength: imageBytes.length,
      contentType: 'image/jpeg',
    );

    return "https://$bucket.s3.$region.amazonaws.com/$objectKey";
  }



  void deletePhoto() {
    setState(() {
      photo = null;
      webPhoto = null;
      photoUrl = null;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("✅ Photo deleted")),
    );
  }


  Future<void> loadBranches() async {
    final list = await _controller.getBranches("1"); // cid = 1

    setState(() {
      branchList = list;
      isLoading = false;
    });
  }
  Future<void> loadShift() async{
    final list=await _shiftController.fetchShifts("1");
    setState(() {
      shiftList=list;
      isShiftLoading=false;
    });
  }
  Future<void> loadDepartment() async{
    final list=await _departmentController.fetchDepartments("1");
    setState(() {
      departmentList=list;
      isDepartLoading=false;
    });
  }
  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    photoUrl = null;

  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          backgroundColor: Colors.blue,
          iconTheme: IconThemeData(color: Colors.white),
          title: const Text("Create User",style: TextStyle(color: Colors.white,fontSize: 18),)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                  controller: useridCtrl,
                  decoration: const InputDecoration(
                      hint: Row(
                        children: [
                          Text("User Id "),
                          Text("*",style: TextStyle(color: Colors.red),),
                        ],
                      ),
                      border: OutlineInputBorder())),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(controller: passwordCtrl,
                  decoration: const InputDecoration(
                      hint: Row(
                        children: [
                          Text("Password "),
                          Text("*",style: TextStyle(color: Colors.red),),
                        ],
                      ),
                  border: OutlineInputBorder())),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(controller: nameCtrl, decoration: const InputDecoration(
                  hint: Row(
                    children: [
                      Text("Full Name "),
                      Text("*",style: TextStyle(color: Colors.red),),
                    ],
                  ),
                  border: OutlineInputBorder())),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(controller: emailCtrl, decoration: const InputDecoration(
                  hint: Row(
                    children: [
                      Text("Email "),
                      Text("*",style: TextStyle(color: Colors.red),),
                    ],
                  ),
                  border: OutlineInputBorder())),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(controller: phoneCtrl,
                  decoration: const InputDecoration(
                      hint: Row(
                        children: [
                          Text("Phone "),
                          Text("*",style: TextStyle(color: Colors.red),),
                        ],
                      ),
                      border: OutlineInputBorder())),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: DropdownButtonFormField<String>(
                value: selectedGender,
                decoration: const InputDecoration(
                  labelText: "Gender",
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(
                    value: "Male",
                    child: Text("Male"),
                  ),
                  DropdownMenuItem(
                    value: "Female",
                    child: Text("Female"),
                  ),
                ],
                onChanged: (value) {
                  setState(() {
                    selectedGender = value;
                    genderCtrl.text = value ?? "";
                    debugPrint(selectedGender);
                    debugPrint(genderCtrl.text);
                  });
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(controller: fullAddressCtrl, decoration: const InputDecoration(labelText: "Full Address",border: OutlineInputBorder())),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextFormField(
                controller: dateController,
                readOnly: true,
                onTap: () => selectDate(context),
                decoration: const InputDecoration(
                  labelText: "Date of Joining",
                  hintText: "DD-MM-YYYY",
                  border: OutlineInputBorder(),
                  suffixIcon: Icon(Icons.calendar_today),
                ),
              ),
            ),
            //branch
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : DropdownButtonFormField<String>(
                hint: Row(
                  children: [
                    Text("Select Kiosk "),
                    Text("*",style: TextStyle(color: Colors.red),),
                  ],
                ),
                value: selectedBranchId,
                items: branchList.map((branch) {
                  return DropdownMenuItem<String>(
                    value: branch.id,
                    child: Text(branch.branchName),
                  );
                }).toList(),
                onChanged: (value) {
                  final branch = branchList.firstWhere(
                        (b) => b.id == value,
                  );

                  setState(() {
                    selectedBranchId = branch.id;
                    selectedBranchName = branch.branchName;
                    selectedBranchLat = branch.lat;
                    selectedBranchLong = branch.long;
                    selectedBranchDistance = branch.distance;
                  });

                  debugPrint("Selected Branchid: ${branch.id}");
                  debugPrint("Selected BranchName: ${branch.branchName}");
                  debugPrint("Selected BranchLat: ${branch.lat}");
                  debugPrint("Selected BranchLong: ${branch.long}");
                  debugPrint("Selected BranchDist: ${branch.distance}");
                },
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            //shift
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: isShiftLoading? const Center(child: CircularProgressIndicator()):
              DropdownButtonFormField<String>(
                hint: Row(
                  children: [
                    Text("Select Shift "),
                    Text("*",style: TextStyle(color: Colors.red),),
                  ],
                ),
                value: selectedShiftId,
                items: shiftList.map((shift) {
                  return DropdownMenuItem<String>(
                    value: shift.shiftId,
                    child: Text("${shift.shiftStart} - ${shift.shiftEnd}"),
                  );
                }).toList(),
                onChanged: (value) {
                  final shift = shiftList.firstWhere(
                        (b) => b.shiftId == value,
                  );

                  setState(() {
                    selectedShiftId = shift.shiftId;
                    selectedShiftStart = shift.shiftStart;
                    selectedShiftEnd = shift.shiftEnd;
                  });

                  debugPrint("Selected shiftid: ${shift.shiftId}");
                  debugPrint("Selected shiftstart: ${shift.shiftStart}");
                  debugPrint("Selected shiftend: ${shift.shiftEnd}");
                },
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                ),
              ),),
            //department
            Padding(padding: EdgeInsets.all(8.0),
            child: isDepartLoading?const Center(
              child: CircularProgressIndicator()):DropdownButtonFormField<String>(
              hint: Row(
                children: [
                  Text("Select User Type "),
                  Text("*",style: TextStyle(color: Colors.red),),
                ],
              ),
                value: selectedDepartId,
                items: departmentList.map((depart){
                  return DropdownMenuItem(
                    value: depart.id,
                      child: Text(depart.name),
                  );
                }).toList(),
                onChanged: (value){
                  final department=departmentList.firstWhere((b)=>b.id==value,);
                  setState(() {
                    selectedDepartId=department.id;
                    selectedDepartName=department.name;
                  });
                  debugPrint("Selected departId: ${department.id}");
                  debugPrint("Selected departName: ${department.name}");
                },
            decoration: InputDecoration(
              border: OutlineInputBorder(),
            ),),),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Container(
                    height: 80,
                    width: 80,
                    decoration: BoxDecoration(
                      color: Colors.green,
                      border: Border.all(color: Colors.black),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Stack(
                      children: [
                        Center(
                          child: isLoadingPhoto
                              ? const CircularProgressIndicator()
                              : kIsWeb
                              ? webPhoto == null
                              ? InkWell(
                            onTap: () => pickImagePhoto1(
                                ImageSource.gallery),
                            child: const Text(
                              "No image\nselected",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  fontSize: 8,
                                  color: Colors.white),
                            ),
                          )
                              : Image.memory(
                            webPhoto!,
                            fit: BoxFit.cover,
                            width: 75,
                            height: 75,
                          )
                              : photo == null
                              ? InkWell(
                            onTap: () async{
                              final imageUrl = await pickImagePhoto1(ImageSource.camera);
                              print("Uploaded Image URL: $imageUrl");

                            },
                            child: const Text(
                              "No image\nselected",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  fontSize: 8,
                                  color: Colors.white),
                            ),
                          )
                              : Image.file(
                            photo!,
                            fit: BoxFit.cover,
                            width: 75,
                            height: 75,
                          ),
                        ),
                        if (photo != null || webPhoto != null)
                          Positioned(
                            top: -2,
                            right: -2,
                            child: InkWell(
                              onTap: deletePhoto,
                              child: Container(
                                decoration: const BoxDecoration(
                                  color: Colors.black,
                                  shape: BoxShape.circle,
                                ),
                                padding: const EdgeInsets.all(4),
                                child: const Icon(
                                  Icons.delete_forever,
                                  size: 18,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: loading ? null : submitUser,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue, // 🔥 Punch out color
                foregroundColor: Colors.white,
                elevation: 3,
                padding: const EdgeInsets.symmetric(
                  horizontal: 30,
                  vertical: 10,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                textStyle: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              child: loading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text("Create User"),
            )
          ],
        ),
      ),
    );
  }
}
