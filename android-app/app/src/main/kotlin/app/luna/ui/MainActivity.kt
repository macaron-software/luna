package app.luna.ui

import android.os.Bundle
import android.view.accessibility.AccessibilityEvent
import androidx.appcompat.app.AppCompatActivity
import androidx.navigation.fragment.NavHostFragment
import androidx.navigation.ui.setupWithNavController
import app.luna.R
import app.luna.databinding.ActivityMainBinding
import app.luna.services.VaultService

/**
 * MainActivity — point d'entrée de l'app.
 * NavHostFragment gère Home / Calendar / Insights / Settings.
 * Le BottomNavigationView suit les fragments via NavController.
 */
class MainActivity : AppCompatActivity() {

    private lateinit var binding: ActivityMainBinding

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        binding = ActivityMainBinding.inflate(layoutInflater)
        setContentView(binding.root)

        val navHost = supportFragmentManager
            .findFragmentById(R.id.nav_host_fragment) as NavHostFragment
        val navController = navHost.navController

        binding.bottomNavigation.setupWithNavController(navController)

        // a11y : décrire la navigation pour TalkBack
        binding.bottomNavigation.setOnItemSelectedListener { item ->
            navController.navigate(item.itemId)
            sendAccessibilityEvent(AccessibilityEvent.TYPE_VIEW_FOCUSED)
            true
        }
    }

    override fun onResume() {
        super.onResume()
        // Si le vault est verrouillé → afficher LockActivity
        if (!VaultService.isUnlocked) {
            LockActivity.start(this)
        }
    }
}
