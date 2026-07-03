import 'package:googleapis_auth/auth_io.dart';

class GetServerKey {
  final scopes = [
    'https://www.googleapis.com/auth/userinfo.email',
    'https://www.googleapis.com/auth/firebase.database',
    'https://www.googleapis.com/auth/firebase.messaging',
  ];

  Future<String> getServerKeyToken() async {
    final client = await clientViaServiceAccount(
      ServiceAccountCredentials.fromJson({
        "type": "service_account",
        "project_id": "joizone",
        "private_key_id": "aff6e3fcad2c4f298f66503fe9f5ab09c54022b1",
        "private_key": "-----BEGIN PRIVATE KEY-----\nMIIEvQIBADANBgkqhkiG9w0BAQEFAASCBKcwggSjAgEAAoIBAQCfeQq3U4jyLqn0\npSmQcnBopNF0px6lTFNxwUk+nC3euVT+QeuJPcvA4YDcIXq6m/TMiYDaSmUJXGBs\nxUrhXv6NSbCrpZiSoW9sB06iZy3IhYIV72UIk4jqqeWeF44sxC1eHkkQy45xTBT0\non9sVzT5rpcJ9d8KXzQEouUT9jCjqrWPK1N1NqIdkdvlICLdL/UtXrG6FACaINDG\nqzFQ4+hjq7UwZtt74bJBlrEAX5j7yI5PVWYKXztMBmzm7jsgvsVI2Qv8iqz0Wxdv\n2bkXIu6dVu/6ONEFfkYV7Fn3CjVAqTyOW4fd2YjzIoBIdZaLAN/Lwi5TFLymqgYW\ni2hOPlZ7AgMBAAECggEABPWTR2eNKsUG/1tFZn8rxomU0BHzM/Wznp2KPYICzICv\nGG4qX1E7yRaCuObZXidU6VyD/xsxB/sGlOYHpxuBGDvb9gyv04IyG/116sNn3SaY\nIk9t5C9i5veznZiE//Z118mEp4FBUI7u8cPXYN3gVpqhJDifRnKQatQ6Ak75/fvg\nSLZ4c2ZBp4nD+hBEkkhjivzG4Hw47+Msx5RbPPDFBkkhkn/+RjLNwlF1Vli0WtV+\n8AQJ5n3yr1ba7D5PUeiCXpleCHGGOy/d0y8uuhFk6t91vyZNgmqC5G9GYFCUCYIM\n3bjX1oFKMeSqvUHnliPaGrFPa8E+NI0EThn0B/t8OQKBgQDUJFDac8ABJNMOfzqu\nvhHU6HVa7A1pRmuJyhdQ1liHjEQq0OZQFZqvtXETbDDCGdd2zRhHTOFAq3/PVon+\nshR5pHOI5nms6ZW91VuLL02rmlYzINpqrep8/NrP3mkcb8Avmvv0kHqpKdBN1sUV\nFECFgsN+Au+Akgy0Ut9EJIlP9QKBgQDAcTK9Gi2eMTMxtLb1ALmpGj1SW9npzhIp\nPV3WavOBHbWWOgZQMDjdAirM6GT/a5P3/e7vRukxjr0dHK0cW5gUq5smy6ktzvf4\nEvfMBkhDVpgvvQza7zXMqeRG4Tuixj9qFLJBpV+F7X0gTqfd3WLTrChI3Isd/mMl\nnEQC5Jc2rwKBgQDMfi1KRuXAtISWpuIka6e4ulPVz1GmN3GWIy6Sh+xSzU0wkKpS\nbGDuG1LizBm8ITjnlhBfOqavtiG/9cWTtIm0MGgGgVSs74WetjpGUtTmJCIPqw2g\nZAFzdjJeyiA8fySdPyK8v0DeLCZVwj+8cAc6K7DSmXXRU/fXI0OA5k9OuQKBgHZ0\nNxsXRgUdm7l41zUv4Rgpwp0zVIsKATvJPj2BT6mmM+Poi4JIbHf9oYLHeYOPIGGB\nuNUn/No4VkfZIuVVq+LtTm8u5VABGbllU4oOQ+TPJJYd9A+/Nopn+M94TFEBXn9Z\nhe/Kb2XsrRx5zfJPF0nbqmBPAILR1w2LhoGRW1KZAoGAdnBUczxJR1+baeVgfrdg\n0RHu/gD4je20tF/AijUaXR0oQGRh1/OvzKbksBMr69THqugAWnAOUtRsMc/peLFa\n8y2Bo2vGrhl1Ojlhxrflyi8/PkBkH3ybWmF1aAaZFTYyCF6+d3tihoSE2n2VGdqB\nPausknft1k++hfwTWofO78E=\n-----END PRIVATE KEY-----\n",
        "client_email": "firebase-adminsdk-fbsvc@joizone.iam.gserviceaccount.com",
        "client_id": "109678875622417439397",
        "auth_uri": "https://accounts.google.com/o/oauth2/auth",
        "token_uri": "https://oauth2.googleapis.com/token",
        "auth_provider_x509_cert_url": "https://www.googleapis.com/oauth2/v1/certs",
        "client_x509_cert_url": "https://www.googleapis.com/robot/v1/metadata/x509/firebase-adminsdk-fbsvc%40joizone.iam.gserviceaccount.com",
        "universe_domain": "googleapis.com"
      }),
      scopes,
    );
    final accessServerKey = client.credentials.accessToken.data;
    return accessServerKey;
  }
}
