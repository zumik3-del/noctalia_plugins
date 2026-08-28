function formatPct(fraction) {
    const v = fraction * 100;
    if (!isFinite(v))
        return "\u2014";
    const r = Math.round(v * 10) / 10;
    return (Number.isInteger(r) ? r.toString() : r.toFixed(1)) + "%";
}
