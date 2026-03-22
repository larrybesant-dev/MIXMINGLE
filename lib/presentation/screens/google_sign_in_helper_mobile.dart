import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'google_sign_in_helper_stub.dart';

class GoogleSignInHelperMobile implements GoogleSignInHelper {
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;

  @override
  Future<void> signInWithGoogle() async {
    final GoogleSignInAccount googleUser = await _googleSignIn.authenticate();
    final GoogleSignInAuthentication googleAuth = googleUser.authentication;
    final AuthCredential credential = GoogleAuthProvider.credential(
      idToken: googleAuth.idToken,
      accessToken: googleAuth.accessToken,
    );
    await FirebaseAuth.instance.signInWithCredential(credential);
  }
}

extension on GoogleSignInAuthentication {
  String? get accessToken => null;
}

GoogleSignInHelper getGoogleSignInHelper() => GoogleSignInHelperMobile();
