/**
 * Heurystyka wyciągająca parametry wyszukiwania karty MTG z surowego plaintekstu OCR.
 * Zwraca tylko pola sensownie odczytane; brak/niepasujące → undefined.
 */

export interface CardScanResult {
  name?: string;
  set?: string;
  collectorNumber?: string;
}

const TYPE_WORDS = new Set([
  "creature", "instant", "sorcery", "enchantment", "artifact", "land",
  "planeswalker", "summon", "battle", "tribal", "conspiracy",
  "enchant", "basic", "legendary",
]);

function isTypeLine(line: string): boolean {
  const tokens = line
    .toLowerCase()
    .replace(/[^a-z ]/g, " ")
    .replace(/\s+/g, " ")
    .trim()
    .split(" ");
  return tokens.slice(0, 2).some((t) => TYPE_WORDS.has(t));
}

function isNoise(line: string): boolean {
  const letters = line.replace(/[^A-Za-z]/g, "");
  if (letters.length < 2) return true;
  if (!/[a-z]/.test(line)) return true;
  return false;
}

function extractName(lines: string[]): string | undefined {
  for (const line of lines) {
    if (isTypeLine(line) || isNoise(line)) continue;
    return line.replace(/\s+/g, " ").trim();
  }
  return undefined;
}

/** Kod setu: 3 alnum tuż przed tokenem języka druku (EN, JP, …). */
function findSet(lines: string[]): { set?: string; lineIndex: number } {
  const LANG = "EN|JP|FR|DE|IT|ES|PT|RU|KO|CS|CT|CN";
  const re = new RegExp(
    `(?:^|\\s)([A-Z0-9]{3})\\s*[•*.\\u00B7\\u2022\\-]?\\s*(?:${LANG})\\b`,
    "g",
  );
  let set: string | undefined;
  let lineIndex = -1;
  for (let i = 0; i < lines.length; i++) {
    re.lastIndex = 0;
    const m = re.exec(lines[i]);
    if (m) {
      set = m[1];
      lineIndex = i;
    }
  }
  return { set, lineIndex };
}

const normNum = (s: string) => s.replace(/[Oo]/g, "0");

const isYear = (n: string) => /^(?:19|20)\d\d$/.test(n);

function extractCollector(lines: string[], setLineIndex: number): string | undefined {
  const slashRe = /\b([0-9Oo]{1,4})\s*\/\s*([0-9Oo]{1,3})\b/g;
  const rarityNum = /\b[CURMLSTP]\s*([0Oo][0-9Oo]{2,3})(?![0-9Oo\-])/;
  const leadZero = /\b(0[0-9Oo]{2,3})(?![-0-9Oo])/;
  const wizardsTrailing = /wizard.*\s([0-9Oo]{3,4})\s*$/i;

  for (const line of lines) {
    slashRe.lastIndex = 0;
    let m: RegExpExecArray | null;
    while ((m = slashRe.exec(line))) {
      const left = normNum(m[1]);
      const right = normNum(m[2]);
      const isPadded = /^0\d/.test(left) || /^0\d/.test(right);
      const bigRight = parseInt(right, 10) > 17;
      if (isPadded || bigRight) return `${left}/${right}`;
    }
  }
  for (const line of lines) {
    const m = rarityNum.exec(line);
    if (m) return normNum(m[1]);
  }
  for (const line of lines) {
    const m = leadZero.exec(line);
    if (m) return normNum(m[1]);
  }
  for (const line of lines) {
    const m = wizardsTrailing.exec(line);
    if (m) {
      const num = normNum(m[1]);
      if (!isYear(num)) return num;
    }
  }

  if (setLineIndex >= 0) {
    const candidates: { num: string; dist: number }[] = [];
    for (let i = 0; i < lines.length; i++) {
      const t = lines[i].trim();
      if (!/^[0-9Oo]{3,4}$/.test(t)) continue;
      const num = normNum(t);
      if (isYear(num)) continue;
      candidates.push({ num, dist: Math.abs(i - setLineIndex) });
    }
    if (candidates.length) {
      candidates.sort((a, b) => a.dist - b.dist);
      return candidates[0].num;
    }
  }

  return undefined;
}

export function parseCardScan(raw: string): CardScanResult {
  const lines = raw
    .split(/\r?\n/)
    .map((l) => l.trim())
    .filter(Boolean);

  const result: CardScanResult = {};
  const name = extractName(lines);
  const { set, lineIndex } = findSet(lines);
  const collectorNumber = extractCollector(lines, lineIndex);

  if (name) result.name = name;
  if (set) result.set = set;
  if (collectorNumber) result.collectorNumber = collectorNumber;
  return result;
}
