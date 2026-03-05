package app.luna.ui

import android.os.Bundle
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import androidx.fragment.app.Fragment
import androidx.recyclerview.widget.GridLayoutManager
import app.luna.R
import app.luna.databinding.FragmentCalendarBinding
import java.time.LocalDate
import java.time.YearMonth
import java.time.format.TextStyle
import java.util.Locale

/**
 * CalendarFragment — vue calendrier mensuelle.
 * Affiche une grille 7 colonnes avec coloration phase cycle.
 * Navigation mois précédent/suivant.
 */
class CalendarFragment : Fragment() {

    private var _binding: FragmentCalendarBinding? = null
    private val binding get() = _binding!!
    private var displayedMonth: YearMonth = YearMonth.now()

    override fun onCreateView(
        inflater: LayoutInflater, container: ViewGroup?, savedInstanceState: Bundle?
    ): View {
        _binding = FragmentCalendarBinding.inflate(inflater, container, false)
        return binding.root
    }

    override fun onViewCreated(view: View, savedInstanceState: Bundle?) {
        super.onViewCreated(view, savedInstanceState)

        setupNavigation()
        renderMonth()
    }

    private fun setupNavigation() {
        binding.prevMonthButton.apply {
            setOnClickListener {
                displayedMonth = displayedMonth.minusMonths(1)
                renderMonth()
            }
            // a11y: cible ≥ 48dp
            contentDescription = getString(R.string.previous_month_a11y)
        }

        binding.nextMonthButton.apply {
            setOnClickListener {
                displayedMonth = displayedMonth.plusMonths(1)
                renderMonth()
            }
            contentDescription = getString(R.string.next_month_a11y)
        }
    }

    private fun renderMonth() {
        val locale = Locale.getDefault()
        val monthName = displayedMonth.month.getDisplayName(TextStyle.FULL, locale)
        binding.monthTitle.text = "$monthName ${displayedMonth.year}"
        binding.monthTitle.contentDescription = binding.monthTitle.text

        // Construire la liste des jours pour ce mois
        val firstDay = displayedMonth.atDay(1)
        val daysInMonth = displayedMonth.lengthOfMonth()
        // Décalage pour commencer la grille au bon jour de la semaine
        val startOffset = (firstDay.dayOfWeek.value % 7) // Lun=1..Dim=7 → 0-based dimanche

        val days = mutableListOf<CalendarDay?>()
        repeat(startOffset) { days.add(null) } // cellules vides
        for (d in 1..daysInMonth) {
            days.add(CalendarDay(date = displayedMonth.atDay(d)))
        }

        binding.calendarGrid.apply {
            layoutManager = GridLayoutManager(requireContext(), 7)
            adapter = CalendarDayAdapter(days) { day ->
                // Ouvrir LogBottomSheet pour ce jour
                val sheet = LogBottomSheet()
                sheet.show(parentFragmentManager, LogBottomSheet.TAG)
            }
        }
    }

    override fun onDestroyView() {
        super.onDestroyView()
        _binding = null
    }
}

// ── Data + Adapter ─────────────────────────────────────────────────────────

data class CalendarDay(
    val date: LocalDate,
    val eventType: CalendarEventType = CalendarEventType.NONE,
)

enum class CalendarEventType { NONE, PERIOD, FERTILE, OVULATION, LOGGED }

class CalendarDayAdapter(
    private val days: List<CalendarDay?>,
    private val onDayClick: (CalendarDay) -> Unit,
) : androidx.recyclerview.widget.RecyclerView.Adapter<CalendarDayAdapter.DayViewHolder>() {

    inner class DayViewHolder(itemView: View) :
        androidx.recyclerview.widget.RecyclerView.ViewHolder(itemView) {
        val dayText: android.widget.TextView = itemView.findViewById(android.R.id.text1)
    }

    override fun onCreateViewHolder(parent: ViewGroup, viewType: Int): DayViewHolder {
        val v = LayoutInflater.from(parent.context)
            .inflate(android.R.layout.simple_list_item_1, parent, false)
        return DayViewHolder(v)
    }

    override fun onBindViewHolder(holder: DayViewHolder, position: Int) {
        val day = days[position]
        if (day == null) {
            holder.dayText.text = ""
            holder.dayText.isClickable = false
            holder.itemView.contentDescription = "" // a11y : cellule vide ignorée
            holder.itemView.importantForAccessibility =
                View.IMPORTANT_FOR_ACCESSIBILITY_NO
        } else {
            holder.dayText.text = day.date.dayOfMonth.toString()
            holder.itemView.setOnClickListener { onDayClick(day) }
            // a11y : date complète pour TalkBack
            holder.itemView.contentDescription = day.date.format(
                java.time.format.DateTimeFormatter.ofPattern("EEEE d MMMM", Locale.getDefault())
            )
            holder.itemView.importantForAccessibility =
                View.IMPORTANT_FOR_ACCESSIBILITY_YES
            // Fond coloré selon type d'événement
            val colorRes = when (day.eventType) {
                CalendarEventType.PERIOD -> android.R.color.holo_red_light
                CalendarEventType.FERTILE -> android.R.color.holo_green_light
                CalendarEventType.OVULATION -> android.R.color.holo_orange_light
                CalendarEventType.LOGGED -> android.R.color.darker_gray
                CalendarEventType.NONE -> android.R.color.transparent
            }
            holder.itemView.setBackgroundColor(
                androidx.core.content.ContextCompat.getColor(holder.itemView.context, colorRes)
            )
        }
    }

    override fun getItemCount() = days.size
}
