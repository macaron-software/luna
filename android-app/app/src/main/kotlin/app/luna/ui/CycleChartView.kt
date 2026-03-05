package app.luna.ui

import android.content.Context
import android.graphics.*
import android.util.AttributeSet
import android.view.View
import androidx.core.content.ContextCompat
import app.luna.R

/**
 * CycleChartView — graphique de tendance des cycles.
 * Dessin custom Canvas, aucune dépendance tierce.
 * Supporte: barres (longueurs cycles), ligne (BBT, poids).
 */
class CycleChartView @JvmOverloads constructor(
    context: Context, attrs: AttributeSet? = null, defStyle: Int = 0
) : View(context, attrs, defStyle) {

    enum class ChartType { BAR, LINE }

    var chartType: ChartType = ChartType.BAR
    var dataPoints: List<Pair<String, Float>> = emptyList()
        set(value) { field = value; invalidate() }
    var yMin: Float = 0f
    var yMax: Float = 40f
    var labelY: String = ""

    private val barPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
        style = Paint.Style.FILL
    }
    private val linePaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
        style = Paint.Style.STROKE
        strokeWidth = 3f
        strokeCap = Paint.Cap.ROUND
        strokeJoin = Paint.Join.ROUND
    }
    private val pointPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
        style = Paint.Style.FILL
    }
    private val gridPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
        style = Paint.Style.STROKE
        strokeWidth = 1f
        color = Color.parseColor("#22888888")
    }
    private val labelPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
        textSize = 24f
        textAlign = Paint.Align.CENTER
    }

    override fun onAttachedToWindow() {
        super.onAttachedToWindow()
        val accent = try {
            ContextCompat.getColor(context, R.color.luna_brand_primary)
        } catch (e: Exception) { Color.parseColor("#8B20DC") }
        barPaint.color = accent
        linePaint.color = accent
        pointPaint.color = accent
        labelPaint.color = try {
            ContextCompat.getColor(context, android.R.color.secondary_text_dark)
        } catch (e: Exception) { Color.DKGRAY }
    }

    override fun onDraw(canvas: Canvas) {
        super.onDraw(canvas)
        if (dataPoints.isEmpty()) return
        val padL = 60f; val padR = 20f; val padT = 20f; val padB = 50f
        val w = width.toFloat() - padL - padR
        val h = height.toFloat() - padT - padB
        val range = (yMax - yMin).takeIf { it > 0f } ?: 1f

        // Grid lines (3)
        repeat(3) { i ->
            val yVal = yMin + range * i / 2
            val yPx = padT + h - h * (yVal - yMin) / range
            canvas.drawLine(padL, yPx, padL + w, yPx, gridPaint)
            labelPaint.textAlign = Paint.Align.RIGHT
            canvas.drawText(String.format("%.0f", yVal), padL - 10f, yPx + 8f, labelPaint)
        }

        val n = dataPoints.size
        when (chartType) {
            ChartType.BAR  -> drawBars(canvas, padL, padT, w, h, range, n)
            ChartType.LINE -> drawLine(canvas, padL, padT, w, h, range, n)
        }
    }

    private fun drawBars(canvas: Canvas, padL: Float, padT: Float, w: Float, h: Float, range: Float, n: Int) {
        val barW = (w / n) * 0.7f
        val gap  = (w / n) * 0.3f
        dataPoints.forEachIndexed { i, (label, value) ->
            val x = padL + i * (w / n) + gap / 2
            val barH = h * (value - yMin) / range
            val top = padT + h - barH
            canvas.drawRoundRect(x, top, x + barW, padT + h, 8f, 8f, barPaint)
            labelPaint.textAlign = Paint.Align.CENTER
            canvas.drawText(label, x + barW / 2, padT + h + 36f, labelPaint)
        }
    }

    private fun drawLine(canvas: Canvas, padL: Float, padT: Float, w: Float, h: Float, range: Float, n: Int) {
        val path = Path()
        dataPoints.forEachIndexed { i, (label, value) ->
            val x = padL + i * w / (n - 1).coerceAtLeast(1)
            val y = padT + h - h * (value - yMin) / range
            if (i == 0) path.moveTo(x, y) else path.lineTo(x, y)
            canvas.drawCircle(x, y, 6f, pointPaint)
            if (i % 3 == 0) {
                labelPaint.textAlign = Paint.Align.CENTER
                canvas.drawText(label, x, padT + h + 36f, labelPaint)
            }
        }
        canvas.drawPath(path, linePaint)
    }

    override fun onMeasure(widthMeasureSpec: Int, heightMeasureSpec: Int) {
        val desiredW = MeasureSpec.getSize(widthMeasureSpec)
        val desiredH = 300
        setMeasuredDimension(desiredW, resolveSize(desiredH, heightMeasureSpec))
    }
}
