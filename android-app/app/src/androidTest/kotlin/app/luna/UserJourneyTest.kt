package app.luna

import androidx.test.core.app.ActivityScenario
import androidx.test.espresso.Espresso.onView
import androidx.test.espresso.action.ViewActions.click
import androidx.test.espresso.assertion.ViewAssertions.matches
import androidx.test.espresso.matcher.ViewMatchers.*
import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.platform.app.InstrumentationRegistry
import app.luna.ui.LockActivity
import app.luna.ui.SettingsActivity
import app.luna.ui.TrackingModeActivity
import org.junit.Test
import org.junit.runner.RunWith

/**
 * Tests de parcours utilisateur Android — Espresso.
 */
@RunWith(AndroidJUnit4::class)
class UserJourneyTest {

    @Test
    fun testAppLaunch_showsLockOrOnboarding() {
        ActivityScenario.launch(LockActivity::class.java).use {
            onView(withId(android.R.id.content)).check(matches(isDisplayed()))
        }
    }

    @Test
    fun testLockScreen_pinButtonsVisible() {
        ActivityScenario.launch(LockActivity::class.java).use {
            onView(withId(R.id.btn1)).check(matches(isDisplayed()))
            onView(withId(R.id.btn0)).check(matches(isDisplayed()))
            onView(withId(R.id.btnDelete)).check(matches(isDisplayed()))
        }
    }

    @Test
    fun testLockScreen_enterPin_updatesDotsContainer() {
        ActivityScenario.launch(LockActivity::class.java).use {
            onView(withId(R.id.btn1)).perform(click())
            onView(withId(R.id.btn2)).perform(click())
            onView(withId(R.id.btn3)).perform(click())
            onView(withId(R.id.pin_dots_container)).check(matches(isDisplayed()))
        }
    }

    @Test
    fun testSettingsActivity_launchesWithoutCrash() {
        val context = InstrumentationRegistry.getInstrumentation().targetContext
        val intent = android.content.Intent(context, SettingsActivity::class.java)
        ActivityScenario.launch<SettingsActivity>(intent).use {
            onView(withId(android.R.id.content)).check(matches(isDisplayed()))
        }
    }

    @Test
    fun testTrackingModeActivity_launchesWithoutCrash() {
        val context = InstrumentationRegistry.getInstrumentation().targetContext
        val intent = android.content.Intent(context, TrackingModeActivity::class.java)
        ActivityScenario.launch<TrackingModeActivity>(intent).use {
            onView(withId(android.R.id.content)).check(matches(isDisplayed()))
        }
    }
}
