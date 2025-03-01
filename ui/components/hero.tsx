import { Button } from "./ui/button";
import Link from "next/link";
import { Link as LinkIcon } from "lucide-react";

export default function Hero() {
  return (
    <div className="flex flex-col items-center text-center py-20">
    <div className="flex items-center gap-2 px-4 py-2 text-xs rounded-full text-primary">
        <span className="font-medium uppercase">LIVE ON TESTNET</span>
        <Link href="#" target="_blank">
          <LinkIcon className="w-4 h-4" />
        </Link>
      </div>

      <h1 className="text-6xl font-semibold mb-4 mt-4">
        Unlock Revolutionary <br />
        <span className="text-primary">Trading Technology</span>
      </h1>

      <h2 className="text-xl text-muted-foreground mb-8 max-w-2xl">
        Experience seamless trading with our advanced dashboard, designed to provide real-time insights and intuitive control over your portfolio.
      </h2>

      <div className="flex gap-4">
        <Button size="lg">
          <Link href="/dashboard">Launch Dashboard</Link>
        </Button>
        <Button variant="outline" size="lg">Documentation</Button>
      </div>
    </div>
  );
}
