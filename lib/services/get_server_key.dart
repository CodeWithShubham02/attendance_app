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
        "private_key_id": "68f1df0ce6291c741a9075e41526e2cd00a1f0ff",
        "private_key": "-----BEGIN PRIVATE KEY-----\nMIIEvQIBADANBgkqhkiG9w0BAQEFAASCBKcwggSjAgEAAoIBAQCvWHKD/qOkK8kw\nHCzBlNFwXicfmjp1Bv7/iU7KG9EtGJxQVrgSDvmr9CuZ5ULqc1k74NcNfPWi1YwF\nlNtrBlXDD3nwRaG7aIECB6nXc+XcfOwyJVPipFZ3K359bQgrsETuryB4jq106kpp\nDQkkSFQ10OdC/Rqvrtiq7WawNJavHYcNPwJujQ9L5+S+0nIReG/SulMM3KpUAxIj\nisRcr284CHh5wy6eOhDSkAPZ23o/VTid2iPGv1Z8yNnfgpoqQHg+bfAMjFnMW0b0\nItBgp5pXGqkhvTGfKLC6SJqX19IztZ2m9KQLDAjN6XObASiBfFa3qcdIokJINRfP\nER9jXA7ZAgMBAAECggEAAkLTS96ZThk5cYB01vSGudqg9Frzr4V3qCRlYBz5NsoR\n3psA/yHzIr5AigNnOD46CO1hNd2QuPjkzWqfZLMoIR6JOD8G8vN0nGnXDRNDxB2B\nRIlE2mU7md2f9oPqKSQPU35DHoLae5Q3gZYch3uo8v5es7dZ+X4j8ZpOQBiW1oBh\nu6lHU4Q0vZ7pQwZYGMX/1WnmQalSVYREt5Pm0xlKmmVbuye+OduE0VNQatgkVqG9\nVEYPN5KKeiuCJgw66F8ssbKu8ljPZx0xzVW++sbFShqM/E8rlBEYxtn9TMrQgup6\njowLtS+vficBGxaXWBgu0vgyQJmDXSNSxe5Z1oemjQKBgQDpHHC1WefH7Z5rTSZl\nwjuRSih6tdFtnJgO7oppc6OZhqCSzP4lNZE0cdUh5EgtOYywsscwsBH1V8dqLy+a\nfc7LoE4mwJ3tWIhWfxGVq6z+dASSm+/lJzxfW1gftBcTRMBnhbzMqyPCwlBeXtgF\npTZaqaWJLw2QmM7YUDyoC/CbfQKBgQDAj/3J+X+cy9NROXJalLsVFkUNNTfrqANq\nc4uhhJCiEAhCat2CTCKpLfmKY9+8KjzEMnKNNs9+kNPMq73E80d4tDl9zsTsKOut\nunLakh3nyJPz+xBbED5BySLfLLlbuu7OxdQtIlgZ3eg4eRC+42JOzyCgG9KncNai\n4UT5Ic4HjQKBgEEHKAHPBLNm++xe5zk3x7ot/8DLe5KiPmDb9kyYb6jiP2T0PmlO\n2iTRJG2B6wiCp1abaKmSVFAmnoBmjVcBhXCUVXjF/sg5DD9kzxj7fRS2dJgZXACG\nw3auWpTtfgpoAWxfiF1n2F/6KMVKm+RnRBRigsUUFSqjFgCN0X3nZsVZAoGAEVdm\nVaAge/BnMXNo9vtZ9cYxpcTbKl/RHu8U7hDQLagf9ktFc4yDupSnWm0wIvPy0QBy\nDIGZIh7M1CvLRUdbcmVYoBnU5iexQc3+texewRbxLBG6IVlPIgGJIGwYrUgiZYCv\nYPks0feICD3u4iH8InjIyWJ4EBg7XCPJYF5I/akCgYEAvjt9Yevja0ICdYat89Mt\nENVL5ValSnwP6KSuq0fCeZoSez0wXyx4OWzO8dNzAUhHlZ0Y6ISgKdbjCGCcXNxI\n13kGp7B6eE5sR2sxRb45V5JwitW9786+0IEjcDvIhNHSYas3cItKdFmD7fvGTffl\n7+ZOlJ7IEyJbs5xaErn0SUM=\n-----END PRIVATE KEY-----\n",
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
