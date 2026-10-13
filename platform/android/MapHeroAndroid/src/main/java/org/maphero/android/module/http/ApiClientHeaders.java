package org.maphero.android.module.http;

import android.content.Context;
import android.content.pm.PackageInfo;
import android.content.pm.PackageManager;
import android.content.pm.Signature;
import android.content.pm.SigningInfo;
import android.os.Build;
import android.util.Log;

import org.maphero.android.MapHero;

import java.security.MessageDigest;
import java.util.Locale;

/**
 * What this application tells MapHero about itself, on every request.
 *
 * <h2>The credential</h2>
 *
 * <p>{@code X-API-Key} is the header the platform is moving to; {@code map-token} is the one every
 * previously shipped SDK sent. <strong>Both go out together.</strong> The server picks its
 * authentication path from the credential's own prefix ({@code mh_pk_} / {@code mh_sk_} or neither)
 * rather than from the header it arrived in, so one value works in either — but the legacy header
 * cannot simply be dropped, because nginx in front of the tile and asset host reads it <em>by
 * name</em> ({@code proxy_set_header X-Map-Token $http_map_token}). Without it a tile request
 * arrives with no token at all and is refused for anything not served from a {@code maphero.io}
 * page. A request carrying both is resolved by a documented precedence, not rejected.
 *
 * <h2>The application claim</h2>
 *
 * <p>An API key can be restricted to named Android applications, and the server checks the package
 * name and — where the restriction carries one — the signing certificate's SHA-256. Those arrive in
 * {@code X-MapHero-Android-Package} and {@code X-MapHero-Android-Cert}. Until now no Android SDK
 * sent either, so that restriction could only ever refuse this SDK.
 *
 * <p><strong>These are claims, not proof.</strong> An application chooses every header it sends, so
 * this raises the cost of casual key theft and establishes nothing against a determined attacker;
 * real proof needs Play Integrity. The server's own {@code ApiClientInfo} says the same thing, and
 * the distinction matters: these values are worth sending, and are not worth trusting.
 *
 * <h2>Computed once</h2>
 *
 * <p>None of this changes while the process lives — the package name and the signing certificate of
 * an installed application are fixed — and {@code PackageManager} is not free, so it is read once
 * and remembered. A failure to read it is not a failure to make the request: the header is left out
 * and the key's other restrictions still apply.
 */
final class ApiClientHeaders {

    static final String HEADER_API_KEY = "X-API-Key";
    static final String HEADER_LEGACY_TOKEN = "map-token";
    static final String HEADER_ANDROID_PACKAGE = "X-MapHero-Android-Package";
    static final String HEADER_ANDROID_CERT = "X-MapHero-Android-Cert";
    static final String HEADER_CLIENT = "X-MapHero-Client";

    /**
     * Which SDK is calling, for attribution and support — never as a grant.
     *
     * <p>It is self-declared, exactly as the package name is, so it cannot gate access: a key that
     * were granted on the strength of this header would be granted to anyone who sends it. What it
     * does answer is which SDK a customer's traffic and refusals are coming from, and which SDKs
     * still need migrating off {@code map-token} — the question that gates the sunset date.
     *
     * <p>A Flutter or React Native application embeds this SDK and will report {@code android}: the
     * value names the SDK making the request, and those wrappers should override it with their own
     * once they have one.
     */
    static final String CLIENT_ANDROID = "android";

    /** A secret key is server-only and is never a legacy map token, so it is not duplicated. */
    private static final String SECRET_KEY_PREFIX = "mh_sk_";

    private static final String TAG = "Mbgl-ApiClientHeaders";

    private static volatile String packageName;
    private static volatile String certSha256;
    private static volatile boolean resolved;

    private ApiClientHeaders() {
    }

    /** True when the credential should also travel in the deprecated header. */
    static boolean alsoSendLegacyHeader(String credential) {
        return credential != null && !credential.isEmpty() && !credential.startsWith(SECRET_KEY_PREFIX);
    }

    static String androidPackage() {
        resolve();
        return packageName;
    }

    static String androidCertSha256() {
        resolve();
        return certSha256;
    }

    private static void resolve() {
        if (resolved) {
            return;
        }
        synchronized (ApiClientHeaders.class) {
            if (resolved) {
                return;
            }
            // Marked resolved first: a context that is not available yet must not make every
            // request retry a lookup that will keep failing for the same reason.
            resolved = true;
            try {
                Context context = MapHero.getApplicationContext();
                if (context == null) {
                    return;
                }
                packageName = context.getPackageName();
                certSha256 = signingCertificate(context);
            } catch (Exception unavailable) {
                // Deliberately broad: nothing here is worth failing a map request over.
                Log.w(TAG, "Could not read this application's identity: " + unavailable.getMessage());
            }
        }
    }

    /**
     * The SHA-256 of the certificate this application was signed with, uppercase hex.
     *
     * <p>Uppercase and unseparated because that is the form the server normalises a stored
     * restriction to, and the comparison there is exact string equality.
     *
     * <p>The first signer only. An application with several is outside what the restriction can
     * express, and picking one arbitrarily would be a silent mismatch rather than an obvious one.
     */
    @SuppressWarnings("deprecation")
    private static String signingCertificate(Context context) throws Exception {
        PackageManager packages = context.getPackageManager();
        String name = context.getPackageName();
        Signature[] signatures;
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
            PackageInfo info = packages.getPackageInfo(name, PackageManager.GET_SIGNING_CERTIFICATES);
            SigningInfo signing = info.signingInfo;
            if (signing == null) {
                return null;
            }
            signatures = signing.hasMultipleSigners()
                    ? signing.getApkContentsSigners()
                    : signing.getSigningCertificateHistory();
        } else {
            signatures = packages.getPackageInfo(name, PackageManager.GET_SIGNATURES).signatures;
        }
        if (signatures == null || signatures.length == 0) {
            return null;
        }
        byte[] digest = MessageDigest.getInstance("SHA-256").digest(signatures[0].toByteArray());
        StringBuilder hex = new StringBuilder(digest.length * 2);
        for (byte b : digest) {
            hex.append(String.format(Locale.US, "%02X", b));
        }
        return hex.toString();
    }
}
