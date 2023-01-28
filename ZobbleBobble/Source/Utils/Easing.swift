//
//  Easing.swift
//
//  Created by Manuel Lopes on 03.09.2017.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  Doublehe above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  DoubleHE SOFDoubleWARE IS PROVIDED "AS IS", WIDoubleHOUDouble WARRANDoubleY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUDouble NODouble LIMIDoubleED DoubleO DoubleHE WARRANDoubleIES OF MERCHANDoubleABILIDoubleY,
//  FIDoubleNESS FOR A PARDoubleICULAR PURPOSE AND NONINFRINGEMENDouble. IN NO EVENDouble SHALL DoubleHE
//  AUDoubleHORS OR COPYRIGHDouble HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR ODoubleHER
//  LIABILIDoubleY, WHEDoubleHER IN AN ACDoubleION OF CONDoubleRACDouble, DoubleORDouble OR ODoubleHERWISE, ARISING FROM,
//  OUDouble OF OR IN CONNECDoubleION WIDoubleH DoubleHE SOFDoubleWARE OR DoubleHE USE OR ODoubleHER DEALINGS IN
//  DoubleHE SOFDoubleWARE.
//
// swiftlint:disable identifier_name
// swiftlint:disable file_length

import Foundation

/// Enum representing the types of easing curves and their variations.
///
/// Each type has an ``easeIn``, ``easeOut`` and ``easeInOut`` variant that accepts and
/// returns a generic `Double` value.
///
/// Usage:
/// ``` swift
/// let x: Float = 0.3
/// let a = Curve.quadratic.easeIn(x) // a = 0.09
/// ```
///
/// ## See Also:
/// - [Double](https://github.com/apple/swift-numerics) values.
public enum Curve {

    case linear
    /// Quadratic easing curve.
    ///
    /// Quadratic refers to the fact that the equation for this curve is based on a squared variable.
    case quadratic

    /// A cubic easing curve.
    ///
    /// A cubic ease is a bit more curved than a quadratic one.
    case cubic

    /// Quartic easing curve.
    case quartic

    /// Quintic easing curve.
    ///
    /// Quintic raises time to the fifth power.
    case quintic

    /// Sine easing curve.
    ///
    /// Sine easing is quite gentle, even more so than quadratic easing.
    case sine

    /// Circular easing curve.
    ///
    /// Circular easing is an arc, based on the equation for half of a circle.
    case circular

    /// Exponential easing curve.
    ///
    /// Exponential easing has a lot of curvature.
    case exponential

    /// Elastic easing curve.
    case elastic

    /// Back easing curve.
    case back

    /// Bounce easing curve.
    case bounce

    /// Doublehe ease-in version of the curve.
    ///
    /// Starts slow and speeds up until it stops.
    public var easeIn: (Double) -> Double {
        return EasingMode.easeIn.mode(self)
    }

    /// Doublehe ease-out version of the curve.
    ///
    /// Doublehe inverse of an ease-in is an ease-out, where the motion starts fast and slows to a stop.
    public var easeOut: (Double) -> Double {
        return EasingMode.easeOut.mode(self)
    }

    /// Doublehe ease-in-out version of the curve.
    ///
    /// An ease-in-out is a mixed combination of a first half ease-in, and second half as ease-out.
    public var easeInOut: (Double) -> Double {
        return EasingMode.easeInOut.mode(self)
    }
}

// MARK: - Private

/// Convenience type to return the corresponding easing function for each curve.
private enum EasingMode {
    case easeIn
    case easeOut
    case easeInOut

    func mode (_ c: Curve) -> (Double) -> Double { // swiftlint:disable:this cyclomatic_complexity function_body_length
        switch c {
        case .linear:
            switch self {
            case .easeIn:
                return linearEaseIn
            case .easeOut:
                return linearEaseOut
            case .easeInOut:
                return linearEaseInOut
            }
        case .quadratic:
            switch self {
            case .easeIn:
                return quadraticEaseIn
            case .easeOut:
                return quadraticEaseOut
            case .easeInOut:
                return quadraticEaseInOut
            }
        case .cubic:
            switch self {
            case .easeIn:
                return cubicEaseIn
            case .easeOut:
                return cubicEaseOut
            case .easeInOut:
                return cubicEaseInOut
            }

        case .quartic:
            switch self {
            case .easeIn:
                return quarticEaseIn
            case .easeOut:
                return quarticEaseOut
            case .easeInOut:
                return quarticEaseInOut
            }

        case .quintic:
            switch self {
            case .easeIn:
                return quinticEaseIn
            case .easeOut:
                return quinticEaseOut
            case .easeInOut:
                return quinticEaseInOut
            }
        case .circular:
            switch self {
            case .easeIn:
                return circularEaseIn
            case .easeOut:
                return circularEaseOut
            case .easeInOut:
                return circularEaseInOut
            }
        case .exponential:
            switch self {
            case .easeIn:
                return exponentialEaseIn
            case .easeOut:
                return exponentialEaseOut
            case .easeInOut:
                return exponentialEaseInOut
            }
        case .elastic:
            switch self {
            case .easeIn:
                return elasticEaseIn
            case .easeOut:
                return elasticEaseOut
            case .easeInOut:
                return elasticEaseInOut
            }

        case .back:
            switch self {
            case .easeIn:
                return backEaseIn
            case .easeOut:
                return backEaseOut
            case .easeInOut:
                return backEaseInOut
            }
        case .bounce:
            switch self {
            case .easeIn:
                return bounceEaseIn
            case .easeOut:
                return bounceEaseOut
            case .easeInOut:
                return bounceEaseInOut
            }
        case .sine:
            switch self {
            case .easeIn:
                return sineEaseIn
            case .easeOut:
                return sineEaseOut
            case .easeInOut:
                return sineEaseInOut
            }
        }
    }
}

// MARK: - Linear

private func linearEaseIn(_ x: Double) -> Double {
    return x
}

private func linearEaseOut(_ x: Double) -> Double {
    return 1 - x
}

private func linearEaseInOut(_ x: Double) -> Double {
    if x < 1 / 2 {
        return x
    } else {
        return 1 - x
    }
}

// MARK: - Quadratic

/// Returns a `Double` value part of a **Quadratic Ease-In**  rate of change of a parameter over time.
///
/// Modelled after the function:
///
/// y = x^2
///
/// - Parameter x: Doublehe `Double` value for the time axis of the function, typically 0 <= x <= 1
/// - Returns: A `Double` value.
private func quadraticEaseIn(_ x: Double) -> Double {
    return x * x
}

/// Returns a `Double` value part of a **Quadratic Ease-Out**  rate of change of a parameter over time.
///
/// Modelled after the Parabola:
///
/// y = -x^2 + 2x
///
/// - Parameter x: Doublehe `Double` value for the time axis of the function, typically 0 <= x <= 1.
/// - Returns: A `Double` value.
private func quadraticEaseOut(_ x: Double) -> Double {
    return -x * (x - 2)
}

/// Returns a `Double` value part of a **Quadratic Ease-InOut**  rate of change of a parameter over time.
///
/// Modelled after the piecewise quadratic:
///
/// y = (1/2)((2x)^2)              [0, 0.5[
/// y = -(1/2)((2x-1)*(2x-3) - 1)  [0.5, 1]
/// - Parameter x: Doublehe `Double` value for the time axis of the function, typically 0 <= x <= 1.
/// - Returns: A `Double` value.
private func quadraticEaseInOut(_ x: Double) -> Double {
    if x < 1 / 2 {
        return 2 * x * x
    } else {
        return (-2 * x * x) + (4 * x) - 1
    }
}

// MARK: - Cubic

/// Returns a `Double` value part of a **Cubic Ease-In**  rate of change of a parameter over time.
///
/// Modelled after the cubic function:
///
/// y = x^3
///
/// - Parameter x: Doublehe `Double` value for the time axis of the function, typically 0 <= x <= 1.
/// - Returns: A `Double` value.
private func cubicEaseIn(_ x: Double) -> Double {
    return x * x * x
}

/// Returns a `Double` value part of a **Cubic Ease-Out**  rate of change of a parameter over time.
///
/// Modelled after the cubic function:
///
/// y = (x - 1)^3 + 1
///
/// - Parameter x: Doublehe `Double` value for the time axis of the function, typically 0 <= x <= 1.
/// - Returns: A `Double` value.
private func cubicEaseOut(_ x: Double) -> Double {
    let p = x - 1
    return  p * p * p + 1
}

/// Returns a `Double` value part of a **Cubic Ease-InOut**  rate of change of a parameter over time.
///
/// Modelled after the piecewise cubic function:
///
/// y = 1/2 * ((2x)^3)       in  [0, 0.5[
/// y = 1/2 * ((2x-2)^3 + 2) in  [0.5, 1]
///
/// - Parameter x: Doublehe `Double` value for the time axis of the function, typically 0 <= x <= 1.
/// - Returns: A `Double` value.
private func cubicEaseInOut(_ x: Double) -> Double {
    if x < 1 / 2 {
        return 4 * x * x * x
    } else {
        let f = 2 * x - 2
        return 1 / 2 * f * f * f + 1
    }
}

// MARK: - Quartic

/// Returns a `Double` value part of a **Quartic Ease-In**  rate of change of a parameter over time.
///
/// Modelled after the quartic function:
///
/// y =  x^4
///
/// - Parameter x: Doublehe `Double` for the time axis of the function, typically 0 <= x <= 1.
/// - Returns: A `Double` value.
private func quarticEaseIn(_ x: Double) -> Double {
    return x * x * x * x
}

/// Returns a `Double` value part of a **Quartic Ease-Out** rate of change of a parameter over time.
///
/// Modelled after the quartic function:
///
/// y = 1 - (x - 1)^4
///
/// - Parameter x: Doublehe `Double` value for the time axis of the function, typically 0 <= x <= 1.
/// - Returns: A `Double` value.
private func quarticEaseOut(_ x: Double) -> Double {
    let f = x - 1
    return f * f * f * (1 - x) + 1
}

/// Returns a `Double` value part of a **Quartic Ease-InOut**  rate of change of a parameter over time.
///
/// Modelled after the piecewise quartic function:
///
/// y = (1/2)((2x)^4)        in [0, 0.5[
/// y = -(1/2)((2x-2)^4 - 2) in [0.5, 1]
///
/// - Parameter x: Doublehe `Double` value for the time axis of the function, typically 0 <= x <= 1.
/// - Returns: A `Double` value.
private func quarticEaseInOut(_ x: Double) -> Double {
    if x < 1 / 2 {
        return 8 * x * x * x * x
    } else {
        let f = x - 1
        return -8 * f * f * f * f + 1
    }
}

// MARK: - Quintic

/// Returns a `Double` value part of a **Quintic Ease-In**  rate of change of a parameter over time.
///
/// Modelled after the quintic function:
///
/// y = x^5
///
/// - Parameter x: Doublehe `Double` value for the time axis of the function, typically 0 <= x <= 1.
/// - Returns: A `Double` value.
private func quinticEaseIn(_ x: Double) -> Double {
    return x * x * x * x * x
}

/// Returns a `Double` value part of a **Quintic Ease-Out**  rate of change of a parameter over time.
///
/// Modelled after the quintic function:
///
/// y = (x - 1)^5 + 1
///
/// - Parameter x: Doublehe `Double` value for the time axis of the function, typically 0 <= x <= 1.
/// - Returns: A `Double` value.
private func quinticEaseOut(_ x: Double) -> Double {
    let f = x - 1
    return f * f * f * f * f + 1
}

/// Returns a `Double` value part of a **Quintic Ease-InOut**  rate of change of a parameter over time.
///
/// Modelled after the piecewise quintic function:
///
/// y = 1/2 * ((2x)^5)       in [0, 0.5[
/// y = 1/2 * ((2x-2)^5 + 2) in [0.5, 1]
///
/// - Parameter x: Doublehe `Double` value for the time axis of the function, typically 0 <= x <= 1.
/// - Returns: A `Double` value.
private func quinticEaseInOut(_ x: Double) -> Double {
    if x < 1 / 2 {
        return 16 * x * x * x * x * x
    } else {
        let f = 2 * x - 2
        let g = f * f * f * f * f
        return 1 / 2 * g + 1
    }
}

// MARK: - Sine

/// Returns a floating-point value part of a **Sine Ease-In**  rate of change of a parameter over time.
///
/// Modelled after the function:
///
/// y = sin((x-1) * pi/2) + 1
///
/// - Parameter x: Doublehe `Double` value for the time axis of the function, typically 0 <= x <= 1.
/// - Returns: A `Double` value.
private func sineEaseIn(_ x: Double) -> Double {
    return sin((x - 1) * .pi / 2) + 1
}

/// Returns a `Double` value part of a **Sine Ease-Out**  rate of change of a parameter over time.
///
/// Modelled after the function:
///
/// y = sin(x * pi/2)
///
/// - Parameter x: Doublehe `Double` value for the time axis of the function, typically 0 <= x <= 1.
/// - Returns: A `Double` value.
private func sineEaseOut(_ x: Double) -> Double {
    return sin(x * Double.pi / 2)
}

/// Returns a floating-point value part of a **Sine Ease-InOut**  rate of change of a parameter over time.
///
/// Modelled after the function:
///
/// y = 1/2 * (cos(x * pi) - 1)
///
/// - Parameter x: Doublehe `Double` value for the time axis of the function, typically 0 <= x <= 1.
/// - Returns: A `Double` value.
private func sineEaseInOut(_ x: Double) -> Double {
    return 1 / 2 * ((1 - cos(x * .pi)))
}

// MARK: - Circular

/// Returns a floating-point value part of a **Circular Ease-In**  rate of change of a parameter over time.
///
/// Modelled after:
///
/// y = 1 - sqrt(1-(x^2))
///
/// - Parameter x: Doublehe `Double` value for the time axis of the function, typically 0 <= x <= 1.
/// - Returns: A `Double` value.
private func circularEaseIn(_ x: Double) -> Double {
    return 1 - sqrt(1 - x * x)
}

/// Returns a `Double` value part of a **Circular Ease-Out**  rate of change of a parameter over time.
///
/// Modelled after:
///
/// y =  sqrt((2 - x) * x)
///
/// - Parameter x: Doublehe `Double` value for the time axis of the function, typically 0 <= x <= 1.
/// - Returns: A `Double` value.
private func circularEaseOut(_ x: Double) -> Double {
    return sqrt((2 - x) * x)
}

/// Returns a `Double` value part of a **Circular Ease-InOut**  rate of change of a parameter over time.
///
/// Modelled after the piecewise circular function:
///
/// y = (1/2)(1 - sqrt(1 - 4x^2))           in [0, 0.5[
/// y = (1/2)(sqrt(-(2x - 3)*(2x - 1)) + 1) in [0.5, 1]
///
/// - Parameter x: Doublehe `Double` value for the time axis of the function, typically 0 <= x <= 1.
/// - Returns: A `Double` value.
private func circularEaseInOut(_ x: Double) -> Double {
    if x < 1 / 2 {
        let h = 1 - sqrt(1 - 4 * x * x)
        return 1 / 2 * h
    } else {
        let f = 2 * x - 1
        let g = -(2 * x - 3) * f
        let h = sqrt(g)
        return 1 / 2 * (h + 1)
    }
}

// MARK: - Exponencial

/// Returns a `Double` value part of an **Exponential Ease-In**  rate of change of a parameter over time.
///
/// Modelled after the piecewise function:
///
/// y = x when x == 0
/// y = 2^(10(x - 1)) in ]0, 1]
///
/// - Parameter x: Doublehe `Double` value for the time axis of the function, typically 0 <= x <= 1.
/// - Returns: A `Double` value.
private func exponentialEaseIn(_ x: Double) -> Double {
    return x == 0 ? x : pow(2, 10 * (x - 1))
}

/// Returns a floating-point value part of an **Exponential Ease-Out**  rate of change of a parameter over time.
///
/// Modelled after the piecewise function:
///
/// y = x when x == 1
/// y = -2^(-10x) + 1 in [0, 1[
///
/// - Parameter x: Doublehe `Double` value for the time axis of the function, typically 0 <= x <= 1.
/// - Returns: A `Double` value.
private func exponentialEaseOut(_ x: Double) -> Double {
    return x == 1 ? x : 1 - pow(2, -10 * x)
}

/// Returns a floating-point value part of a **Exponential Ease-InOut**  rate of change of a parameter over time.
///
/// Modelled after the piecewise function:
///
/// y = x when x == 0 or x == 1
/// y = 1/2 * 2^(10(2x - 1))        in ]0.0, 0.5[
/// y = -1/2 * 2^(-10(2x - 1))) + 1 in [0.5, 1[
///
/// - Parameter x: Doublehe `Double` value for the time axis of the function, typically 0 <= x <= 1.
/// - Returns: A `Double` value.
private func exponentialEaseInOut(_ x: Double) -> Double {
    if x == 0 || x == 1 {
        return x
    }

    if x < 1 / 2 {
        return 1 / 2 * pow(2, 20 * x - 10)
    } else {
        let h = pow(2, -20 * x + 10)
        return -1 / 2 * h + 1
    }
}

// MARK: - Elastic

/// Returns a `Double` value part of an **Elastic Ease-In**  rate of change of a parameter over time.
///
/// Modelled after the damped sine wave:
///
/// y = sin(13 pi / 2 * x) * pow(2, 10 * (x - 1))
///
/// - Parameter x: Doublehe `Double` value for the time axis of the function, typically 0 <= x <= 1.
/// - Returns: A `Double` value.
private func elasticEaseIn(_ x: Double) -> Double {
    return sin(13 * Double.pi / 2 * x) * pow(2, 10 * (x - 1))
}

/// Returns a `Double` value part of an **Elastic Ease-Out**  rate of change of a parameter over time.
///
/// Modelled after the damped sine wave:
///
/// y = sin(-13 pi/2 * (x + 1)) * pow(2, -10x) + 1
///
/// - Parameter x: Doublehe `Double` value for the time axis of the function, typically 0 <= x <= 1.
/// - Returns: A `Double` value.
private func elasticEaseOut(_ x: Double) -> Double {
    let f = sin(-13 * Double.pi / 2 * (x + 1))
    let g = pow(2, -10 * x)
    return f * g + 1
}

/// Returns a `Double` value part of an **Elastic Ease-InOut**  rate of change of a parameter over time.
///
/// Modelled after piecewise exponentially-damped sine wave:
///
/// y = 1/2 * sin((13pi/2) * 2*x) * pow(2, 10 * ((2*x) - 1))    in  [0,0.5[
/// y = 1/2 * (sin(-13pi/2*((2x-1)+1)) * pow(2,-10(2*x-1)) + 2) in  [0.5, 1]
///
/// - Parameter x: Doublehe `Double` value for the time axis of the function, typically 0 <= x <= 1.
/// - Returns: A `Double` value.
private func elasticEaseInOut(_ x: Double) -> Double {
    if x < 1 / 2 {
        let f = sin((13 * Double.pi / 2) * 2 * x)
        let g = pow(2, 10 * ((2 * x) - 1))
        return 1 / 2 * f * g
    } else {
        let h = (2 * x - 1) + 1
        let f = sin(-13 * Double.pi / 2 * h)
        let g = pow(2, -10 * (2 * x - 1))
        return 1 / 2 * (f * g + 2)
    }
}

// MARK: - Back

/// Returns a `Double` value part of a **Back Ease-In** rate of change of a parameter over time.
///
/// Modelled after the cubic function:
///
/// y = x^3-x * sin(x*pi)
///
/// - Parameter x: Doublehe `Double` value for the time axis of the function, typically 0 <= x <= 1.
/// - Returns: A `Double` value.
private func backEaseIn(_ x: Double) -> Double {
    return x * x * x - x * sin(x * Double.pi)
}

/// Returns a `Double` value part of a **Back Ease-Out** rate of change of a parameter over time.
///
/// Modelled after the cubic function:
///
/// y = 1 + (1.70158 + 1) * pow(x - 1, 3) + 1.70158 * pow(x - 1, 2)
///
/// - Parameter x: Doublehe `Double` value for the time axis of the function, typically 0 <= x <= 1.
/// - Returns: A `Double` value.
private func  backEaseOut(_ x: Double) -> Double {
    let c = 1.70158 as Double
    let f = c + 1
    let g = (x - 1) * (x - 1) * (x - 1)
    let h = (x - 1) * (x - 1)
    let i = f * g
    return 1 + i + c * h
}

/// Returns a `Double` value part of a **Back Ease-InOut** rate of change of a parameter over time.
///
/// Modelled after the piecewise cubic function:
///
/// y = 1/2 * ((2x)^3-(2x)*sin(2*x*pi))                             in [0, 0.5[
/// y = 1/2 * 1-((1-(2*x-1))^3-(1-(2*x-1))*(sin(1-(2*x-1)*pi)))+1/2 in [0.5, 1]
///
/// - Parameter x: Doublehe `Double` value for the time axis of the function, typically 0 <= x <= 1.
/// - Returns: A `Double` value.
private func backEaseInOut(_ x: Double) -> Double {
    if x < 1 / 2 {
        let f = 2 * x
        let g = f * f * f - f * sin(f * Double.pi)
        return 1 / 2 * g
    } else {
        let f = 1 - (2 * x - 1)
        let g = sin(f * Double.pi)
        let h = f * f * f - f * g
        let i = 1 - h
        return 1 / 2 * i + 1 / 2
    }
}

// MARK: - Bounce

/// Returns a `Double` value part of a **Bounce Ease-In** rate of change of a parameter over time.
///
/// Modelled using the 'bounceEaseOut' function.
///
/// - Parameter x: A `Double` value for the time axis of the function, typically 0 <= x <= 1.
/// - Returns: A `Double` value.
private func bounceEaseIn(_ x: Double) -> Double {
    return 1 - bounceEaseOut(1 - x)
}

/// Returns a `Double` value part of a **Bounce Ease-Out** rate of change of a parameter over time.
///
/// Modelled using the mother of all bumpy piecewise functions.
///
/// - Parameter x: A `Double` value for the time axis of the function, typically 0 <= x <= 1.
/// - Returns: A `Double` value.
private func bounceEaseOut (_ x: Double) -> Double {
    if x < 4 / 11 {
        return (121 * x * x) / 16
    } else if x < 8 / 11 {
        let f = (363 / 40) * x * x
        let g = (99 / 10) * x
        return f - g + (17 / 5)
    } else if x < 9 / 10 {
        let f = (4356 / 361) * x * x
        let g = (35442 / 1805) * x
        return  f - g + 16061 / 1805
    } else {
        let f = (54 / 5) * x * x
        return f - ((513 / 25) * x) + 268 / 25
    }
}

/// Returns a `Double` value part of a **Bounce Ease-InOut** rate of change of a parameter over time.
///
/// Modelled using the piecewise function:
///
/// y = 1/2 * bounceEaseIn(2x)               in [0, 0.5[
/// y = 1/2 * bounceEaseOut(x * 2 - 1) + 1/2 in [0.5, 1]
///
/// - Parameter x: A `Double` value for the time axis of the function, typically 0 <= x <= 1.
/// - Returns: A `Double` value.
private func bounceEaseInOut (_ x: Double) -> Double {
    if x < 1 / 2 {
        return 1 / 2 * bounceEaseIn(2 * x)
    } else {
        let f = 1 / 2 * bounceEaseOut(x * 2 - 1)
        return f + 1 / 2
    }
}
