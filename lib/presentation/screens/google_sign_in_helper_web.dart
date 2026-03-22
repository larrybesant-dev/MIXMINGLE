import 'package:firebase_auth/firebase_auth.dart';

import 'google_sign_in_helper_stub.dart';

class GoogleSignInHelperWeb implements GoogleSignInHelper {
  @override
  Future<void> signInWithGoogle() async {
    await FirebaseAuth.instance.signInWithPopup(GoogleAuthProvider());
  }
}

GoogleSignInHelper getGoogleSignInHelper() => GoogleSignInHelperWeb();
