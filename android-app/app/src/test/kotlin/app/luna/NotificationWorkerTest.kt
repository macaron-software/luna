package app.luna

import org.junit.Assert.*
import org.junit.Test

class NotificationWorkerTest {

    @Test
    fun testChannelIds_areDistinct() {
        val channels = listOf(
            app.luna.services.NotificationWorker.CHANNEL_PERIOD,
            app.luna.services.NotificationWorker.CHANNEL_FERTILE,
            app.luna.services.NotificationWorker.CHANNEL_PILL,
        )
        assertEquals(channels.size, channels.distinct().size)
    }

    @Test
    fun testNotifTypes_areDistinct() {
        val types = listOf(
            app.luna.services.NotificationWorker.TYPE_PERIOD,
            app.luna.services.NotificationWorker.TYPE_FERTILE,
            app.luna.services.NotificationWorker.TYPE_PILL,
        )
        assertEquals(types.size, types.distinct().size)
    }

    @Test
    fun testChannelIds_haveExpectedValues() {
        assertEquals("luna_period",  app.luna.services.NotificationWorker.CHANNEL_PERIOD)
        assertEquals("luna_fertile", app.luna.services.NotificationWorker.CHANNEL_FERTILE)
        assertEquals("luna_pill",    app.luna.services.NotificationWorker.CHANNEL_PILL)
    }

    @Test
    fun testNotifTypes_haveExpectedValues() {
        assertEquals("period",  app.luna.services.NotificationWorker.TYPE_PERIOD)
        assertEquals("fertile", app.luna.services.NotificationWorker.TYPE_FERTILE)
        assertEquals("pill",    app.luna.services.NotificationWorker.TYPE_PILL)
    }
}
