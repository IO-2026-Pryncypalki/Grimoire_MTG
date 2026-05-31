import Card from '../collection/Card';
import { CardScanResult, parseCardScan } from './parseCardScan';
import ScryfallScanResolver from './ScryfallScanResolver';

export type ScanResolutionKind = 'unique' | 'ambiguous' | 'none';

export interface ScanResolution {
  resolution: ScanResolutionKind;
  parsed: CardScanResult;
  cards: Card[];
  total: number;
}

function resolveScanKind(cards: Card[]): ScanResolutionKind {
  if (cards.length === 0) return 'none';
  if (cards.length === 1) return 'unique';
  return 'ambiguous';
}

export default class ScannerService {
  private resolver: ScryfallScanResolver;

  constructor(data?: { resolver?: ScryfallScanResolver }) {
    this.resolver = data?.resolver ?? new ScryfallScanResolver();
  }

  public async scanFromPlaintext(plaintext: string): Promise<ScanResolution> {
    const trimmed = plaintext?.trim();
    if (!trimmed) {
      throw new Error('Plaintext is required');
    }

    const parsed = parseCardScan(trimmed);
    const { cards, total } = await this.resolver.resolve(parsed);

    return { resolution: resolveScanKind(cards), parsed, cards, total };
  }
}
