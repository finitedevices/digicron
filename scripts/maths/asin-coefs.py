import mpmath as mp

mp.mp.dps = 12

coeffs, error = mp.chebyfit(
    mp.asin,
    (mp.mpf(0), mp.mpf(1) / mp.sqrt(2)),
    9,
    error=True
)

print("Coefficients:", coeffs)
print("Maximum error:", error)